import {strict as assert} from "assert";
import {HttpsError} from "firebase-functions/v2/https";
import {
  parseCoordinates,
  parseGeocodingResults,
  parseSearchQuery,
} from "../../src/maps/geocoding_proxy";

describe("geocoding proxy", () => {
  it("accepts bounded location queries and coordinates", () => {
    assert.equal(parseSearchQuery({query: "  Cafe  "}), "Cafe");
    assert.deepEqual(
      parseCoordinates({latitude: 30, longitude: 31}),
      {latitude: 30, longitude: 31},
    );
  });

  it("rejects invalid input before it reaches Google", () => {
    assert.throws(() => parseSearchQuery({query: ""}), HttpsError);
    assert.throws(
      () => parseCoordinates({latitude: 91, longitude: 31}),
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
});
