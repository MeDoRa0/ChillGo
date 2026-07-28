import {logger} from "firebase-functions";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

const googleMapsGeocodingApiKey = defineSecret("GOOGLE_MAPS_GEOCODING_API_KEY");

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

export const searchMapPlace = onCall(
  {secrets: [googleMapsGeocodingApiKey]},
  async (request) => {
    requireAuthentication(request.auth);
    const query = parseSearchQuery(request.data);
    const results = await requestGeocoding({address: query});
    return {results};
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

function readObject(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "The location request is invalid.");
  }
  return value as Record<string, unknown>;
}
