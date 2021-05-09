import pandas as pd
import os
import difflib
def covid():
    with open("covid19_recovered2.csv", 'r') as infile: 
        with open(os.path.join("processed", "covid19_recovered2.csv"), 'w') as outfile: 
            outfile.write("country,date,recovered\n")


            lines = infile.readlines() 
            header = lines[0].split(',')[1:]

            lines = lines[1:len(lines)]
            newline = ""

            # parse through each line of event flow file 
            for line in lines:

                
                line = line.split(',')
                country = line[0]
                line = line[1:]

                for i, el in enumerate(line):
                    outfile.write(country + "," + header[i].rstrip("\n") + "," + el.rstrip("\n") + "\n")

def filterCountries(fn):
    filterDF = pd.read_csv(fn)
    countriesDF = pd.read_csv(os.path.join("processed", "Countries.csv"))

    filterCountries = filterDF["country"].tolist()
    realCountries= countriesDF["country"].tolist()

    popDiff = list(set(filterCountries) - set(realCountries))

    filterDF = filterDF[~filterDF['country'].isin(popDiff)]

    filterDF.to_csv(fn, index = False)


def filterCountriesVerifier(fn):
    filterDF = pd.read_csv(fn)
    countriesDF = pd.read_csv(os.path.join("processed", "Countries.csv"))

    filterCountries = filterDF["country"].tolist()
    realCountries= countriesDF["country"].tolist()

    popDiff = list(set(filterCountries) - set(realCountries))
    countryDiff = list(set(realCountries) - set(filterCountries) )
    print(popDiff)
    # print(countryDiff)
    for country in popDiff:
        print(country, difflib.get_close_matches(country, countryDiff), difflib.get_close_matches(country.split()[0], countryDiff), "\n")

# covid()
filterCountries(os.path.join("original", "regions.csv"))
    