import processing.serial.*;

String country, region, city;

PImage bg;
PImage img;
PImage term;

int y;
String location = "N/A";
String coordinateS = "N/A";
float area = 0;
float slm = 0;
int pop = 0;
float den = 0;

int flood = 0;
int floodImageY = 766;
float metriPlus = 0.0;
float temperature = 0.0;
int tempRect = 0;
int relativePopulation = 0;
float relativeDensity = 0;
float relativeArea = 0;

Serial myPort;

void setup() {
  fullScreen(2);
  //size(1024, 768);
  bg = loadImage("City.png");
  img = loadImage("Water.png");
  term = loadImage("Temperature.png");

  //Location by IP
  String ip = loadStrings("https://api.ipify.org?format=txt")[0];
  String locationUrl = "https://geo.ipify.org/api/v1?";
  locationUrl += "apiKey=at_fUODzJq6mhJcfWpUghWYvr8YkQ7N2";
  locationUrl += "&ipAddress=";
  locationUrl += ip;

  location = loadStrings(locationUrl)[0];
  println(location);

  //country
  int countryPosO = location.indexOf("country\":\"");
  int countryPosC = location.indexOf("\"", countryPosO + 10);
  country = location.substring(countryPosO + 10, countryPosC);
  println(country);

  //region
  int regionPosO = location.indexOf("region\":\"", countryPosC);
  int regionPosC = location.indexOf("\"", regionPosO + 9);
  region = location.substring(regionPosO + 9, regionPosC);
  println(region);

  //city
  int cityPosO = location.indexOf("city\":\"", regionPosC);
  int cityPosC = location.indexOf("\"", cityPosO + 7);
  city = location.substring(cityPosO + 7, cityPosC);
  //city= "Portogruaro";
  println(city);

  //WIKIPEDIA
  String[] wiki = loadStrings("https://en.wikipedia.org/wiki/" + city);

  for (int i=0; i<wiki.length; i++) {
    int indexI = wiki[i].indexOf("infobox geography vcard");
    int indexIg = wiki[i].indexOf("<span class=\"geo\">"); //COORDINATES  
    int indexIa = wiki[i].indexOf(">Area<div"); //AREA
    int indexIe = wiki[i].indexOf(">Elevation<div"); //ELEVATION
    int indexIl = wiki[i].indexOf(">Population<div"); //POPULATION
    int indexId = wiki[i].indexOf(">Density<div"); //DENSITY

    if (indexIg > 0) {
      int indexO = wiki[i].indexOf("</span>", indexIg + 18);
      coordinateS = trim(wiki[i].substring(indexIg + 18, indexO));
      println(coordinateS);
    }
    if (indexIa > 0) {
      int indexIp = wiki[i].indexOf("<td>", indexIa + 10);
      int indexO = wiki[i].indexOf("&#160;km<sup>2</sup>", indexIp + 4);
      String areaS = trim(wiki[i].substring(indexIp + 4, indexO));
      area = float(trim(areaS).replace(",", "."));
      println(area);
    }
    if (indexIe > 0) {
      int indexIp = wiki[i].indexOf("<td>", indexIe + 14);
      int indexO = wiki[i].indexOf("&#160;m", indexIp + 4);
      String slmS = trim(wiki[i].substring(indexIp + 4, indexO));
      slm = float(trim(slmS).replace(",", "."));
      println(slm);
    }
    if (indexIl > 0) {
      int indexIp = wiki[i].indexOf("<td>", indexIl + 15);
      int indexO = wiki[i].indexOf("</td>", indexIp + 4);
      String popS = trim(wiki[i].substring(indexIp + 4, indexO));
      pop = parseInt(trim(popS).replace(",", "").replace(" ", ""));
      relativePopulation = pop;
      println(pop);
    }
    if (indexId > 0) {
      int indexIp = wiki[i].indexOf("<td>", indexId + 12);
      int indexO = wiki[i].indexOf("<sup>2</sup>", indexIp + 4);
      String denS = trim(wiki[i].substring(indexIp + 4, indexO));
      den = parseInt(trim(denS).replace(",", ".").replace(" ", ""));
      println(den);
    }
  }

  if (den==0) {
    den = pop / area;
  }

  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);  
  myPort.bufferUntil('\n');
}

void draw() {
  background(bg);
  //termometer
  image(term, 928, 15);

  //overlay the data on the picture
  fill(179, 179, 179);

  //TODAY
  //Quote: X 665, 143 Quote Y 102 128 151 208 230 253
  text(slm, 143, 103); //sea level
  text(city, 143, 128); //city
  text(coordinateS, 143, 151); //gps
  text(area, 143, 208); //area
  text(den, 143, 230); //density
  text(pop, 143, 253); //population

  //TOMORROW
  //Quote: X 665, 143 Quote Y 102 128 151 208 230 253
  text(slm - metriPlus, 655, 103); //sea level
  text(city, 655, 128); //city
  text(coordinateS, 655, 151); //gps
  text(relativeArea, 655, 208); //area
  text(relativeDensity, 655, 230); //density
  text(relativePopulation, 655, 253); //population

  //flood
  image(img, 513, floodImageY);

  fill(#ff4a4a);
  noStroke();
  rect(945, 130, 24.4, -tempRect);
}

void keyPressed() {
  //for testing flood image
  println(keyCode);
  if (key >= 48 && key <= 57) {
    flood = key - 48;

    //calculate proportion between 9 meters (4°C) and the slider steps
    metriPlus = map(flood, 0, 9, 0, 9);
    float floodIndex = slm - metriPlus; 
    if (floodIndex < 0) {
      println(floodIndex);
      floodImageY = int(map(floodIndex, 0, -9, 766, 766 - 384));
    }
  }
}

void serialEvent(Serial p)
{
  String valoreArduino = myPort.readString();
  if (valoreArduino != null) {

    valoreArduino = trim(valoreArduino);
    String valori[] = split(valoreArduino, ';');

    if (valori.length > 1) {
      temperature = float(valori[0]);
      println(temperature);

      tempRect = int(map(temperature, 0.5, 4.0, 0, 101));
      floodImageY = int(map(temperature, 0.5, 4.0, 766, 766 - 384));
      //simulation or the population / area / density
      relativePopulation = int(map(temperature, 0.5, 4.0, pop, pop / 2));
      relativeArea = int(map(temperature, 0.5, 4.0, area, area / 3));
      relativeDensity = relativePopulation / relativeArea;
    }
  }
}
