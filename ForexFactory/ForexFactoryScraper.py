from bs4 import BeautifulSoup
import requests
from datetime import date
import time
import os
from datetime import datetime, timedelta
from threading import Timer

today = date.today().strftime('%y.%m.%d')


session = requests.Session()
session.headers['User-Agent'] = 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36'
session.max_redirects = 50


url = 'https://www.forexfactory.com/'
response = session.get(url)
if response.history:
    print ("Request was redirected")
    for resp in response.history:
        print (resp.status_code, resp.url)
    print( "Final destination:")
    print (response.status_code, response.url)
else:
    print ("Request was not redirected")

frontPage = BeautifulSoup(response.content, "html.parser") 

class my_time:
    def __init__(self,given_time, date_time):
        time_string = given_time
        correction = 0         
        if "All Day" in time_string:
            time_string = "00:02"
        if "Tentative" in time_string:
            time_string = "00:02"
        if "am" in time_string:
            time_string = time_string[:-2]
            if time_string[:2]=="12":
                correction = -12
        if "pm" in time_string:     
            time_string = time_string[:-2]
            correction = 12
            print(time_string)
            if "12:" in time_string:
               correction = 0 
        hm = time_string.split(":")
        if len(hm) == 1:
            hm = "26:00"
        self.hour = int(hm[0])+correction
        self.minute = int(hm[1])
        date_string = date_time
        self.date = date_time + " "
    def subtractMinutes(self,diff):
        d = diff
        while d>60:
            self.hour -= 1
            d -= 60
        if d>self.minute:
            self.minute += 60
            self.hour -= 1
        self.minute -= d
    def __repr__(self):
        ans = "%d:%d"%(self.hour,self.minute)
        if self.minute<10: ans += "0"
        hm2 = ans.split(":")
        if len(hm2[0]) == 1:
            ans = "0" + hm2[0] + ":" + hm2[1]
        return ans+":00"


class ff_event:
    def __init__(self, time_=None, currency=None, impact=None, actual=None, forecast=None, previous=None):
        self.time_ = time_
        self.currency = currency
        self.impact = impact
        self.actual = actual
        self.forecast = forecast
        self.previous = previous
    def clean_it(self,text):
        return text
    def __repr__(self):
        ans = "{t:"
        ans += today + " " + self.clean_it(self.time_.__repr__())
        ans += ", c:"
        ans += self.clean_it(self.currency)
        ans += ", i:"
        ans += self.clean_it(self.impact)
        ans += ", a:"
        ans += self.clean_it(self.actual)
        ans += ", f:"
        ans += self.clean_it(self.forecast)
        ans += ", p:"
        ans += self.clean_it(self.previous)
        return ans+"}\n"

ffes = []

for i in range(len(frontPage.findAll('td', 'calendar__cell calendar__time time'))):
    ffes.append(ff_event())

i = 0
for date in frontPage.findAll('span', "date"):
    if date.text!=None: 
        d = date.text
    else:
        d = ffes[i-1].date
    ffes[i].date = d
    i = i + 1

i = 0
for time_ in frontPage.findAll('td', "calendar__cell calendar__time time"):
    t = time_.text
    if len(t.strip())>0:
        ffes[i].time_ = my_time(t, today)
    else:
        ffes[i].time_ = my_time(ffes[i-1].time_.__repr__(), today)
    i = i + 1

i = 0    
for currency in frontPage.findAll('td', "calendar__cell calendar__currency currency"):
    if currency.text!="": c = currency.text.strip()
    ffes[i].currency = c
    i = i + 1

i = 0    
for impact in frontPage.findAll('div', "calendar__impact-icon calendar__impact-icon--screen"):
    span = impact.findChild("span")["class"]
    if len(span)!=0: c = span[0]
    ffes[i].impact = c
    i = i + 1

i = 0    
for actual in frontPage.findAll('td', "calendar__cell calendar__actual actual"):
    c = actual.text.strip()
    ffes[i].actual = c
    i = i + 1

i = 0    
for forecast in frontPage.findAll('td', "calendar__cell calendar__forecast forecast"):
    c = forecast.text.strip()
    ffes[i].forecast = c
    i = i + 1
    
i = 0    
for previous in frontPage.findAll('td', "calendar__cell calendar__previous previous"):
    c = previous.text.strip()
    ffes[i].previous = c
    i = i + 1

def Minus2 (ffe):
    ffe.time_.subtractMinutes(1)

pairs = {}
pairs["JPY"] = "USDJPY"
pairs["EUR"] = "EURUSD"
pairs["CAD"] = "USDCAD"
pairs["USD"] = "USDJPY"
pairs["NZD"] = "NZDUSD"
pairs["AUD"] = "AUDUSD"
pairs["GBP"] = "GBPUSD"
    
print (ffes)


def NewsScraped (): 
    if os.path.exists("C:\\Users\\natep\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\MyDataFile"):
        os.remove("C:\\Users\\natep\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\MyDataFile")
        print("it was removed")
    else:
        print("The file does not exist")
    time.sleep(5)
    fh = open('C:\\Users\\natep\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files\\MyDataFile', 'w')
    report = ""
    count = 0
    for ffe in ffes:
        ok = True
 #       ok = ok and (ffe.impact == "high")
        ok = ok and (ffe.currency != "All")
        ok = ok and (ffe.currency != "Tentative")
        ok = ok and (ffe.currency != "CNY")
        ok = ok and (ffe.currency != "CHF")
        
        if ok:
            count += 1
            ffe.time_.subtractMinutes(1)
            report += "20%s,%s\n"%(today + " " + repr(ffe.time_), pairs[ffe.currency])
    fh.write("%d\n"%(count))
    fh.write(report)
    print ("file was created")

    fh.close
NewsScraped()
