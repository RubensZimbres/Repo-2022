#define DHTTYPE DHT11

#include "DHT.h"

#define DHTPIN 2

DHT dht(DHTPIN, DHTTYPE);

int ledPin = 2;

void setup() {
  Serial.begin(9600);

  dht.begin();
}

void loop() {
  // Wait a few seconds between measurements.
  delay(500);

  // Reading temperature or humidity takes about 250 milliseconds!
  // Sensor readings may also be up to 2 seconds 'old' (its a very slow sensor)
  float h = dht.readHumidity();
  // Read temperature as Celsius (the default)
  float t = dht.readTemperature();

  // Check if any reads failed and exit early (to try again).
  if (isnan(h) || isnan(t)) {
    Serial.println(F("Failed to read from DHT sensor!"));
    return;
  }

  // Compute heat index in Celsius (isFahreheit = false)
  float hic = dht.computeHeatIndex(t, h, false);
  Serial.print("HUM,");
  Serial.print("D,");
  Serial.print(h);
  Serial.print(";");
  
  Serial.print("TEMP,");
  Serial.print("D,");
  Serial.print(t);
  Serial.print(";");
  
  //Serial.print("\n");
  
}
