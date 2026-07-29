import {strict as assert} from "assert";
import {HttpsError} from "firebase-functions/v2/https";
import {
  parseAutocompleteResults,
  parseCoordinates,
  parsePlaceDetails,
  parsePlacesErrorMetadata,
  parseGeocodingResults,
  parseSearchQuery,
  parseSearchBias,
  parseSessionToken,
} from "../../src/maps/geocoding_proxy";

describe("geocoding proxy", () => {
  it("accepts bounded location queries, session tokens, and coordinates", () => {
    assert.equal(parseSearchQuery({query: "  Cafe  "}), "Cafe");
    assert.equal(
      parseSessionToken({sessionToken: "550e8400-e29b-41d4-a716-446655440000"}),
      "550e8400-e29b-41d4-a716-446655440000",
    );
    assert.deepEqual(
      parseCoordinates({latitude: 30, longitude: 31}),
      {latitude: 30, longitude: 31},
    );
    assert.deepEqual(
      parseSearchBias({biasLatitude: 30.0444, biasLongitude: 31.2357}),
      {latitude: 30.0444, longitude: 31.2357},
    );
    assert.equal(parseSearchBias({query: "Cafe"}), null);
  });

  it("rejects invalid input before it reaches Google", () => {
    assert.throws(() => parseSearchQuery({query: ""}), HttpsError);
    assert.throws(() => parseSessionToken({sessionToken: "not-a-token"}), HttpsError);
    assert.throws(
      () => parseCoordinates({latitude: 91, longitude: 31}),
      HttpsError,
    );
    assert.throws(
      () => parseSearchBias({biasLatitude: 30}),
      HttpsError,
    );
  });

  it("returns a bounded, safe map result shape", () => {
    const response = {
      status: "OK",
      results: [
        {
          place_id: "place.1",
          formatted_address: "Cafe, Cairo",
          geometry: {location: {lat: 30, lng: 31}},
        },
      ],
    };

    assert.deepEqual(parseGeocodingResults(response), [
      {id: "place.1", label: "Cafe, Cairo", latitude: 30, longitude: 31},
    ]);
    assert.deepEqual(parseGeocodingResults({status: "ZERO_RESULTS"}), []);
  });

  it("maps Places autocomplete predictions without requesting geometry", () => {
    const response = {
      suggestions: [
        {
          placePrediction: {
            place: "places/ChIJ123",
            text: {text: "Cairo Tower, Zamalek, Egypt"},
          },
        },
        {queryPrediction: {text: {text: "cairo restaurants"}}},
      ],
    };

    assert.deepEqual(parseAutocompleteResults(response), [
      {id: "places/ChIJ123", label: "Cairo Tower, Zamalek, Egypt"},
    ]);
  });

  it("maps a selected Place Details response to one coordinate", () => {
    assert.deepEqual(
      parsePlaceDetails({location: {latitude: 30.0444, longitude: 31.2357}}),
      {latitude: 30.0444, longitude: 31.2357},
    );
  });

  it("extracts only safe Places error metadata", () => {
    assert.deepEqual(
      parsePlacesErrorMetadata({
        error: {
          status: "PERMISSION_DENIED",
          message: "sensitive provider message",
          details: [{reason: "API_KEY_SERVICE_BLOCKED"}],
        },
      }),
      {
        providerStatus: "PERMISSION_DENIED",
        providerReason: "API_KEY_SERVICE_BLOCKED",
      },
    );
    assert.deepEqual(parsePlacesErrorMetadata({unexpected: true}), {});
  });
});
