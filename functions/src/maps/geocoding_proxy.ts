import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

const googleMapsGeocodingApiKey = defineSecret("GOOGLE_MAPS_GEOCODING_API_KEY");
const googleMapsPlacesApiKey = defineSecret("GOOGLE_MAPS_PLACES_API_KEY");

type Coordinates = {
  latitude: number;
  longitude: number;
};

type PlaceResult = {
  id: string;
  label: string;
  latitude: number;
  longitude: number;
};

type PlacePrediction = {
  id: string;
  label: string;
};

type PlacesRequest = {
  path: string;
  apiKey: string;
  fieldMask: string;
  body?: Record<string, unknown>;
  sessionToken?: string;
};

type PlacesErrorMetadata = {
  providerStatus?: string;
  providerReason?: string;
};

export const searchMapPlace = onCall(
  {secrets: [googleMapsPlacesApiKey]},
  async (request) => {
    requireAuthentication(request.auth);
    const query = parseSearchQuery(request.data);
    const sessionToken = parseSessionToken(request.data);
    const bias = parseSearchBias(request.data);
    const results = await requestAutocomplete(query, sessionToken, bias);
    return {results};
  },
);

export const resolveMapPlace = onCall(
  {secrets: [googleMapsPlacesApiKey]},
  async (request) => {
    requireAuthentication(request.auth);
    const placeId = parsePlaceId(request.data);
    const sessionToken = parseSessionToken(request.data);
    return requestPlaceDetails(placeId, sessionToken);
  },
);

export const reverseGeocode = onCall(
  {secrets: [googleMapsGeocodingApiKey]},
  async (request) => {
    requireAuthentication(request.auth);
    const coordinate = parseCoordinates(request.data);
    const results = await requestGeocoding({
      latlng: `${coordinate.latitude},${coordinate.longitude}`,
    });
    return {label: results[0]?.label ?? null};
  },
);

function requireAuthentication(auth: unknown): asserts auth {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in to search for a location.");
  }
}

export function parseSearchQuery(data: unknown): string {
  const query = readObject(data).query;
  if (typeof query !== "string") {
    throw new HttpsError("invalid-argument", "A location query is required.");
  }
  const trimmedQuery = query.trim();
  if (!trimmedQuery || trimmedQuery.length > 120) {
    throw new HttpsError("invalid-argument", "The location query is invalid.");
  }
  return trimmedQuery;
}

export function parseSessionToken(data: unknown): string {
  const sessionToken = readObject(data).sessionToken;
  if (
    typeof sessionToken !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(sessionToken)
  ) {
    throw new HttpsError("invalid-argument", "The map search session is invalid.");
  }
  return sessionToken;
}

export function parseSearchBias(data: unknown): Coordinates | null {
  const source = readObject(data);
  const latitude = source.biasLatitude;
  const longitude = source.biasLongitude;
  if (latitude === undefined && longitude === undefined) return null;
  return parseCoordinates({latitude, longitude});
}

export function parsePlaceId(data: unknown): string {
  const placeId = readObject(data).placeId;
  if (
    typeof placeId !== "string" ||
    !/^places\/[A-Za-z0-9_-]{1,200}$/.test(placeId)
  ) {
    throw new HttpsError("invalid-argument", "The selected place is invalid.");
  }
  return placeId;
}

export function parseCoordinates(data: unknown): Coordinates {
  const source = readObject(data);
  const latitude = source.latitude;
  const longitude = source.longitude;
  if (
    typeof latitude !== "number" ||
    typeof longitude !== "number" ||
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    throw new HttpsError("invalid-argument", "The map coordinate is invalid.");
  }
  return {latitude, longitude};
}

export function parseGeocodingResults(response: unknown): PlaceResult[] {
  const source = readObject(response);
  if (source.status === "ZERO_RESULTS") return [];
  if (source.status !== "OK" || !Array.isArray(source.results)) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  return source.results.slice(0, 5).map(parsePlaceResult);
}

export function parseAutocompleteResults(response: unknown): PlacePrediction[] {
  const suggestions = readObject(response).suggestions;
  if (!Array.isArray(suggestions)) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  return suggestions
    .flatMap((suggestion) => {
      const placePrediction = readObject(suggestion).placePrediction;
      return placePrediction ? [parsePlacePrediction(placePrediction)] : [];
    })
    .slice(0, 5);
}

export function parsePlaceDetails(response: unknown): Coordinates {
  const location = readObject(readObject(response).location);
  const latitude = location.latitude;
  const longitude = location.longitude;
  if (
    typeof latitude !== "number" ||
    typeof longitude !== "number" ||
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  return {latitude, longitude};
}

export function parsePlacesErrorMetadata(
  response: unknown,
): PlacesErrorMetadata {
  const responseSource = recordOrNull(response);
  const providerError = recordOrNull(responseSource?.error);
  const providerStatus = stringOrUndefined(providerError?.status);
  const errorDetails = Array.isArray(providerError?.details) ?
    providerError.details :
    [];
  const providerReason = errorDetails
    .map(recordOrNull)
    .map((detail) => stringOrUndefined(detail?.reason))
    .find((reason) => reason !== undefined);
  return {
    ...(providerStatus === undefined ? {} : {providerStatus}),
    ...(providerReason === undefined ? {} : {providerReason}),
  };
}

async function requestGeocoding(
  parameters: Record<string, string>,
): Promise<PlaceResult[]> {
  const apiKey = googleMapsGeocodingApiKey.value();
  if (!apiKey) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  const url = new URL("https://maps.googleapis.com/maps/api/geocode/json");
  for (const [name, value] of Object.entries(parameters)) {
    url.searchParams.set(name, value);
  }
  url.searchParams.set("key", apiKey);
  let response: Response;
  try {
    response = await fetch(url);
  } catch (error) {
    if (error instanceof TypeError) {
      throw new HttpsError("unavailable", "Location search is unavailable.");
    }
    throw error;
  }
  if (!response.ok) {
    logger.error("google_geocoding_http_error", {status: response.status});
    throw new HttpsError("unavailable", "Location search is unavailable.");
  }
  let payload: unknown;
  try {
    payload = await response.json();
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new HttpsError("internal", "Location search is unavailable.");
    }
    throw error;
  }
  return parseGeocodingResults(payload);
}

async function requestAutocomplete(
  query: string,
  sessionToken: string,
  bias: Coordinates | null,
): Promise<PlacePrediction[]> {
  const apiKey = googleMapsPlacesApiKey.value();
  if (!apiKey) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  const payload = await requestPlaces({
    path: "places:autocomplete",
    apiKey,
    fieldMask:
      "suggestions.placePrediction.place,suggestions.placePrediction.text.text",
    body: {
      input: query,
      sessionToken,
      ...(bias === null ? {} : {locationBias: searchLocationBias(bias)}),
    },
  });
  return parseAutocompleteResults(payload);
}

function searchLocationBias(coordinate: Coordinates): object {
  return {
    circle: {
      center: coordinate,
      radius: 50000,
    },
  };
}

async function requestPlaceDetails(
  placeId: string,
  sessionToken: string,
): Promise<Coordinates> {
  const apiKey = googleMapsPlacesApiKey.value();
  if (!apiKey) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  const payload = await requestPlaces({
    path: placeId,
    apiKey,
    fieldMask: "location",
    sessionToken,
  });
  return parsePlaceDetails(payload);
}

async function requestPlaces(request: PlacesRequest): Promise<unknown> {
  const response = await fetchPlaces(request);
  if (!response.ok) {
    const metadata = await readPlacesErrorMetadata(response);
    logger.error("google_places_http_error", {
      httpStatus: response.status,
      ...metadata,
    });
    throw new HttpsError("unavailable", "Location search is unavailable.");
  }
  return readPlacesJson(response);
}

async function fetchPlaces(request: PlacesRequest): Promise<Response> {
  let response: Response;
  try {
    response = await fetch(placesUrl(request), {
      method: request.body ? "POST" : "GET",
      headers: placesHeaders(request),
      body: request.body ? JSON.stringify(request.body) : undefined,
    });
  } catch (error) {
    if (error instanceof TypeError) {
      logger.error("google_places_transport_error");
      throw new HttpsError("unavailable", "Location search is unavailable.");
    }
    throw error;
  }
  return response;
}

function placesUrl(request: PlacesRequest): URL {
  const url = new URL(`https://places.googleapis.com/v1/${request.path}`);
  if (request.sessionToken) url.searchParams.set("sessionToken", request.sessionToken);
  return url;
}

function placesHeaders(request: PlacesRequest): Record<string, string> {
  const headers: Record<string, string> = {
    "X-Goog-Api-Key": request.apiKey,
    "X-Goog-FieldMask": request.fieldMask,
  };
  if (request.body) headers["Content-Type"] = "application/json";
  return headers;
}

async function readPlacesJson(response: Response): Promise<unknown> {
  try {
    return await response.json();
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new HttpsError("internal", "Location search is unavailable.");
    }
    throw error;
  }
}

async function readPlacesErrorMetadata(
  response: Response,
): Promise<PlacesErrorMetadata> {
  try {
    return parsePlacesErrorMetadata(await response.json());
  } catch (error) {
    if (error instanceof SyntaxError) return {};
    throw error;
  }
}

function recordOrNull(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function stringOrUndefined(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function parsePlaceResult(rawResult: unknown): PlaceResult {
  const source = readObject(rawResult);
  const geometry = readObject(source.geometry);
  const location = readObject(geometry.location);
  const id = source.place_id;
  const label = source.formatted_address;
  const latitude = location.lat;
  const longitude = location.lng;
  if (
    typeof id !== "string" ||
    !id ||
    typeof label !== "string" ||
    !label ||
    typeof latitude !== "number" ||
    typeof longitude !== "number"
  ) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  return {id, label, latitude, longitude};
}

function parsePlacePrediction(rawPrediction: unknown): PlacePrediction {
  const source = readObject(rawPrediction);
  const text = readObject(source.text).text;
  const id = source.place;
  if (
    typeof id !== "string" ||
    !/^places\/[A-Za-z0-9_-]{1,200}$/.test(id) ||
    typeof text !== "string" ||
    !text.trim()
  ) {
    throw new HttpsError("internal", "Location search is unavailable.");
  }
  return {id, label: text};
}

function readObject(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "The location request is invalid.");
  }
  return value as Record<string, unknown>;
}
