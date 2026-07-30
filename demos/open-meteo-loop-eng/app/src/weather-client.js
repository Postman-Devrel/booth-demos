export async function getParisHourlyTemps() {
  const url =
    "https://api.open-meteo.com/v1/forecast" +
    "?latitude=48.85&longitude=2.35&hourly=temperature_2m" +
    "&temperature_unit=fahrenheit";

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Request failed with status ${res.status}`);
  }
  const data = await res.json();

  return data.hourly.temperature_2m;
}
