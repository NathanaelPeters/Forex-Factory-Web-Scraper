# Forex-Factory-Web-Scraper
a Forex Bot that makes orders based on when reports are released according to Forex Factory

# Intro
Forex (FX) is the marketplace where various national currencies are traded. Much like stocks and other financial securities, news plays an important role in how something is priced. This bot was made with the intention of web scraping www.forexfactory.com in order to place an order right before a big news announcement is made. 

# Overview
The bot can be broken down into four steps: scraping the website, creating a files with the information that was scraped, reading the file for the times/currencies and finally, making the orders. 

1. A python file (ForexFactoryScraper.py) will scrape the file using the BeautifulSoup library.
2. The same python script will create (or destroy then create if there is a a current one) a file with the info. (The file is created in a specific location, however I have included an example file (ForexFactoryData(example)) to show how it would look.
3. The application I chose to use was MetaTrader 5, as it came with its own programming language (MQL5) that allows for creating trading robots and technical indicators. The language is based on the concepts of C++. It simply reads the ForexFactoryData file line by line and creates an array of the times (minus 1 minute) and currencies affected by the news reports.
4. The MQL5 file (ForexFactoryBot.ex5) then creates a 'straddle' which is making both a buy and a sell order for the good. (Please see: https://www.babypips.com/learn/forex/letting-the-market-decide-which-direction-to-take if you at all confused about a straddle)

# Installation: 
(The Metatrader 5 application must be downloaded for this bot to work)

1. Download the python file (ForexFactoryScraper.py)
2. Replace the location of the file. "There are two directories (with subdirectories) in which working files can be located: terminal_data_folder\MQL5\FILES\ (in the terminal menu select to view "File" - "Open the data directory");"
3. Dependencies: `pip install beautifulsoup4`
4. Run the python file. As a decoding method, it will show the dates and currencies in the terminal as well as tell you whether the file was created or removed and then created.
5. Download the mql file (ForexFactoryBot.mq5) and compile it.
6. Open MetaTrader5 and click AutoTrading to allow autotrading.
7. Apply the bot to a chart by opening the navigator, clicking Expert Advisors and double clicking "ForexFactoryBot"
