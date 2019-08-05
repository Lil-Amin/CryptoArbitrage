from libcpp.map cimport map
from libcpp.set cimport set
from libcpp.list cimport list
from libcpp.string cimport string
from libcpp cimport bool
from libcpp.stack cimport stack
from libcpp.vector cimport vector
from libc.float cimport FLT_MAX
from config import Currencies, Exchanges, Mandatory_currencies
from multiapi import get_exchange
import math
import historical_data_api as hist_api


cdef struct Edge:
    float Weight
    float Quantity
    string Exchange
    string Price_type
    float Price

cdef struct Vertex:
    float Value
    string Parent

# Tarjan algorithm
cdef struct Tarjan_vertex:
    int index
    int lowlink
    bool onStack

cdef class Tarjan_algorithm:

    cdef map[string, Tarjan_vertex] Tarjan_vertex_list
    cdef int index
    cdef stack[string] S
    cdef map[string, vector[string]] Adjacency_list
    cdef vector[set[string]] SCC_set
    cdef set[string] SCC_element


    cdef int min(self, int first, int second):
        if first < second:
            return first
        else:
            return second


    cdef vector[set[string]] SCC(self, Adjacency_list):
        cdef map[string, vector[string]] Adj = Adjacency_list

        self.index = 0
        self.Adjacency_list = Adjacency_list
        for v in self.Adjacency_list:
            self.Tarjan_vertex_list[v.first].index = -1
        for v in Adj:
            if self.Tarjan_vertex_list[v.first].index == -1:
                self.strong_connection(v.first)

        return self.SCC_set


    cdef void strong_connection(self, string v):
        cdef string w

        self.Tarjan_vertex_list[v].index = self.index
        self.Tarjan_vertex_list[v].lowlink = self.index
        self.index = self.index + 1
        self.S.push(v)
        self.Tarjan_vertex_list[v].onStack = True

        if self.Adjacency_list[v].size() != 0:
            for w_number in range(0, self.Adjacency_list[v].size()):
                w = self.Adjacency_list[v][w_number]
                if self.Tarjan_vertex_list[w].index == -1:
                    self.strong_connection(w)
                    self.Tarjan_vertex_list[v].lowlink = self.min(self.Tarjan_vertex_list[v].lowlink,
                                                                  self.Tarjan_vertex_list[w].lowlink)
                elif self.Tarjan_vertex_list[w].onStack == True:
                    self.Tarjan_vertex_list[v].lowlink = self.min(self.Tarjan_vertex_list[v].lowlink,
                                                                  self.Tarjan_vertex_list[w].index)

        if self.Tarjan_vertex_list[v].lowlink == self.Tarjan_vertex_list[v].index:

            self.SCC_element.clear()
            while w != v:
               w = self.S.top()
               self.S.pop()
               self.Tarjan_vertex_list[w].onStack = False
               self.SCC_element.insert(w)
            self.SCC_set.push_back(self.SCC_element)

# Johnson's algorithm
cdef class Johnsons_algorithm:

    cdef map[string, bool] blocked
    cdef map[string, vector[string]] B
    cdef vector[string] stack
    cdef map[string, vector[string]] A
    cdef vector[set[string]] SCC_set
    cdef string s


    cdef bool v_in_B(self, string v, string w):
        cdef bool x = False
        for i in self.B[w]:
            if i == v:
                x = True
        return x


    cdef void fill_A(self, Adjacency_list):
        cdef map[string, vector[string]] Adj = Adjacency_list

        T = Tarjan_algorithm()
        self.SCC_set = T.SCC(Adjacency_list)

        for i in self.SCC_set:
            for j in i:
                for k in Adj[j]:
                    if i.count(k) != 0 and i.count(j) != 0:
                        self.A[j].push_back(k)


    cdef void unblock(self, string u):
        self.blocked[u] = False
        for w in self.B[u]:
            if self.blocked[w]:
                self.unblock(w)
        self.B[u].clear() # delete w from B(u)


    cdef bool circuit(self, string v):
        cdef bool f = False
        cdef string w1
        self.stack.push_back(v)
        self.blocked[v] = True
        for w in self.A[v]:
            w1 = w
            if w1 == self.s:
                self.stack.push_back(self.stack[0])
                simple_circuits.insert(self.stack)
                self.stack.pop_back()
                f = True
            else:
                if self.blocked[w] != True:
                    if self.circuit(w):
                        f = True
        if f:
            self.unblock(v)
        else:
            for w in self.A[v]:
                if self.v_in_B(v, w) == False:
                    self.B[w].push_back(v)
        self.stack.pop_back()
        return f

    cdef void all_elementary_circuits(self, Adjacency_list):
        self.fill_A(Adjacency_list)
        self.stack.clear()
        for V in self.SCC_set:
            for v in V:
                self.s = v
                for i in V:
                    self.blocked[i] = False
                    self.B[i].clear()
                self.circuit(self.s)
                self.A.erase(v)

cdef set[vector[string]] simple_circuits

# Main function
cpdef main(Pairs, Edges):

    #Graph = nx.DiGraph()

    # Declaration
    cdef map[string, Vertex] Vertex_list
    cdef map[string, Edge] Edge_list
    cdef Edge Edge_info
    cdef Vertex Vertex_info
    cdef map[string, vector[string]] Adjacency_list

    cdef int dash
    cdef string pair, reverse_pair, dash_str = '-'
    cdef float min_ask = FLT_MAX, max_bid = 0
    cdef string ask_exchange, bid_exchange
    cdef vector[vector[string]] SCC_list

    # Convert Python variable to Cython
    for pairs in Edges:

        #Edge_list creation
        Edge_info.Quantity = 0
        Edge_info.Weight = Pairs[pairs]['Weight']
        Edge_info.Price = Pairs[pairs]['Price']
        Edge_info.Price_type = Pairs[pairs]['Price_type'].encode('utf8')
        Edge_info.Exchange = Pairs[pairs]['Exchange'].encode('utf8')
        pair = pairs.encode('utf8')
        Edge_list[pair] = Edge_info

        #Vertex_list creation
        dash = pair.find('-')
        Vertex_info.Value = FLT_MAX
        Vertex_list[pair.substr(0, dash)] = Vertex_info
        Vertex_list[pair.substr(dash+1,)] = Vertex_info

        #Adjacency_list creation
        Adjacency_list[pair.substr(0, dash)].push_back(pair.substr(dash+1,))
        Adjacency_list[pair.substr(dash+1,)]

    # Algorithms using
    import time
    start_time = time.time()

    J = Johnsons_algorithm()
    J.all_elementary_circuits(Adjacency_list)

    # Finding sum of simple circuits and min_circuit
    cdef float sum = 0, min_sum = 0
    cdef vector[string] min_circuit
    cdef string str
    cdef int x

    print('All cycles with sum\n')
    for i in simple_circuits:
        sum = 0
        size = len(i) - 1
        for j in range(len(i)-1):
            str = i[j]
            str.append(dash_str)
            x = j
            #str.append(i[x+1])
            str = str + i[x+1]
            sum = sum + Edge_list[str].Weight
        if sum < min_sum:
            min_sum = sum
            min_circuit = i
        print(i, sum)

    if min_sum == 0:
        print('\nNo negative cycles\n')
    else:
        print('\nNegative cycle exist\n')
        print 'Negative cycle with lowest weight sum ', min_circuit

        #Quantity requests
        quantity_list = []

        for i in range(0, len(min_circuit)-1):
            str = min_circuit[i]
            str.append(dash_str)
            str.append(min_circuit[i+1])

            if Edge_list[str].Quantity == 0:
                reverse_pair = min_circuit[i+1]
                reverse_pair.append(dash_str)
                reverse_pair.append(min_circuit[i])

                if str.decode('utf8') in hist_api.exchange_available_pairs[Edge_list[str].Exchange.decode('utf8')]:
                    if Edge_list[str].Price_type == 'Min Ask':
                        Edge_list[str].Quantity = hist_api.get_orderbook(i)['Quantity']
                        quantity_list.append(Edge_list[str].Quantity)
                else:
                    if Edge_list[str].Price_type == 'Max Bid':
                        Edge_list[str].Quantity = hist_api.get_orderbook(i)['Quantity']
                        quantity_list.append(Edge_list[str].Quantity)

        #print(quantity_list)
        #return(quantity_list)

    #Max available quantity and profit
    str = min_circuit[0] + dash_str + min_circuit[1];

    if Edge_list[str].Price_type == 'Min Ask':
        q0 = Edge_list[str].Quantity * Edge_list[str].Price

    if Edge_list[str].Price_type == 'Max Bid':
        q0 = Edge_list[str].Quantity / Edge_list[str].Price

    quantity = q0
    #print 'begin ', q0, 'q', Edge_list[str].Quantity, 'p', Edge_list[str].Price

    i = 0
    min_circuit_pair = []
    while i < len(min_circuit)-1:
        str = min_circuit[i] + dash_str + min_circuit[i+1];
        min_circuit_pair.append(str)

        q = Edge_list[str].Quantity
        p = Edge_list[str].Price

        if Edge_list[str].Price_type == 'Min Ask':
            quantity = quantity / p
        if Edge_list[str].Price_type == 'Max Bid':
            quantity = quantity * p

        if quantity > q:
            q0 = q/quantity * q0
            quantity = q0
            i = -1

#        if i == len(min_circuit)-2:
#            print 'quantity final ', quantity
#            print 'q0', q0
#            print 'profit ', quantity - q0, min_circuit[i+1]
#            print '\n'

        i = i + 1

    print('')
    i = 0
    quantity = q0
    while i < len(min_circuit)-1:
        str = min_circuit[i] + dash_str + min_circuit[i+1];

        q = Edge_list[str].Quantity
        p = Edge_list[str].Price

        print('Buy {} for {} {} on {}'.format(min_circuit[i+1], quantity, min_circuit[i],
                                           Edge_list[str].Exchange))

        if Edge_list[str].Price_type == 'Min Ask':
            quantity = quantity / p
        if Edge_list[str].Price_type == 'Max Bid':
            quantity = quantity * p

        i = i + 1
    print('\nTotal profit {} {}'.format(quantity - q0, min_circuit[0]))

    Cython_time = time.time() - start_time
    print('\nCython algorithms working time {}'.format(Cython_time))

    return(min_circuit_pair)