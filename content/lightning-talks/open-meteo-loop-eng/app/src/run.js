import { getParisHourlyTemps } from "./weather-client.js";

const temps = await getParisHourlyTemps();

if (Array.isArray(temps)) {
  console.log("temperatures:", temps.slice(0, 5), "...");
  console.log("count:", temps.length);
} else {
  console.error("ERROR: getParisHourlyTemps() did not return an array of temperatures.");
  console.error("got:", temps);
  process.exitCode = 1;
}
