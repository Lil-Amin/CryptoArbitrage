import numpy as np

file = open('historical_data.csv', 'r')
data = np.genfromtxt(file, delimiter=',')
row_of_data = 1

rows = int(data.shape[0] / 31)
data = data.reshape(rows, 31)

get_gap = {
    'BTC-LTC': (0, 6),
    'BTC-ETH': (6, 12),
    'BTC-XRP': (12, 18),
    'ETH-LTC': (18, 22),
    'ETH-XRP': (22, 26)
}

get_exchange_number = {
    'Bittrex': 0,
    'Binance': 1,
    'Poloniex': 2
}

exchange_available_pairs = {
    'Bittrex': {'BTC-LTC', 'BTC-ETH', 'BTC-XRP', 'ETH-LTC', 'ETH-XRP'},
    'Binance': {'BTC-LTC', 'BTC-ETH', 'BTC-XRP', 'ETH-LTC', 'ETH-XRP'},
    'Poloniex': {'BTC-LTC', 'BTC-ETH', 'BTC-XRP'}
}


def get_summary(exchange, pair):
    from_x = get_gap[pair][0]
    to_y = get_gap[pair][1]

    pair_data = data[row_of_data][from_x:to_y]
    ask_data = pair_data[0:int(len(pair_data) / 2)]
    bid_data = pair_data[int(len(pair_data) / 2):]

    ask = ask_data[get_exchange_number[exchange]]
    bid = bid_data[get_exchange_number[exchange]]

    summary = {'Ask': ask,
               'Bid': bid
               }

    return summary


def get_orderbook(i):
    quantity = data[row_of_data][26:][i]

    orderbook = {'Quantity': quantity}

    return orderbook
