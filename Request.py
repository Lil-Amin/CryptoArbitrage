from config import Currencies, Exchanges
from multiapi import get_exchange
import math
import pandas
import main
import time
import historical_data_api as hist_api

Edge_dict = {}


# Price request for all pairs
def main_requests():
    Pairs_data = pandas.DataFrame(index=['Weight', 'Price', 'Exchange', 'Price_type'])

    for i in Currencies:

        Pairs_data['start' + '-' + i] = pandas.Series({'Weight': 0, 'Price_type': 'None', 'Exchange': 'None'})
        Edge_dict['start' + '-' + i] = ''

        for j in Currencies:
            min_ask = float('inf')
            max_bid = 0
            pair = i + '-' + j
            reverse_pair = j + '-' + i

            for ex in Exchanges:

                if pair in hist_api.exchange_available_pairs[ex]:
                    Edge_dict[pair] = ''
                    Edge_dict[reverse_pair] = ''

                    df = hist_api.get_summary(ex, pair)
                    if df['Ask'] < min_ask:
                        min_ask = df['Ask']
                        Pairs_data[pair] = pandas.Series({'Weight': math.log(df['Ask']),
                                                          'Price': df['Ask'],
                                                          'Quantity': 0,
                                                          'Price_type': 'Min Ask',
                                                          'Exchange': ex})

                    if df['Bid'] > max_bid:
                        max_bid = df['Bid']
                        Pairs_data[reverse_pair] = pandas.Series({'Weight': -math.log(df['Bid']),
                                                                  'Price': df['Bid'],
                                                                  'Quantity': 0,
                                                                  'Price_type': 'Max Bid',
                                                                  'Exchange': ex})

    return Pairs_data, Edge_dict


# Quantity request for circuit with lowest weight sum
def side_requests(pair, price_type, exchange):
    if price_type == 'Max Bid':
        dash = pair.find('-')
        reverse_pair = pair[dash + 1:] + '-' + pair[0:dash]

    ex = get_exchange(exchange)()
    ex.get_available_pairs()

    if pair in ex.available_pairs:
        if price_type == 'Min Ask':
            return ex.order_book(pair)[0].iloc[0]['Quantity']
    else:
        if price_type == 'Max Bid':
            return ex.order_book(reverse_pair)[1].iloc[0]['Quantity']


# Call Cython and Request functions
tuple = main_requests()
circuit = main.main(tuple[0], tuple[1])

# Graph drawing
import pygraphviz as pgv

G = pgv.AGraph(directed=True, dpi=300)

for pair in tuple[1]:

    dash = pair.find('-')
    if circuit.count(pair.encode('utf8')) != 0:
        G.add_edge(pair[0:dash], pair[dash + 1:],
                   label=float("{0:.2f}".format(tuple[0][pair].Weight)), color='red')
    else:
        G.add_edge(pair[0:dash], pair[dash + 1:],
                   label=float("{0:.2f}".format(tuple[0][pair].Weight)))

G.draw('graph.png', prog='circo')