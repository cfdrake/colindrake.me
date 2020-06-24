---
title: A Genetic Algorithm in Python
date: 2011-05-01
---

In the spirit of taking biology and artificial intelligence this quarter, I decided to try to throw together a program combining the concepts of the two. I ended up writing a python script that performs "natural selection" of a population of initially random strings towards an ideal "Hello, World" string, implementing a really basic genetic algorithm.

## The Algorithm of Evolution
Before we look at the code, I'm going to go over the basics of how the "algorithms" of [evolution](http://en.wikipedia.org/wiki/Evolution) and genetics work (or at least the simple model of it that we'll use).

To begin, we generate a random initial population of organisms. This will serve as the set of organisms from which we will evolve better, more-fit forms. Next, we implement natural selection by iterating over the following steps for each generation that we would like to simulate:

1. Assign a fitness value to each organism in the population. This should reflect how well the individual is suited to survival in the current environment.
2. Map the fitness value to a probability of being picked to survive into the next generation. Individuals with more fitness should be more likely to be selected to survive.
3. Create a "working population" by choosing individuals from the population with the chance of each being chosen based on their calculated probabilities. This means that individuals can be chosen many times, once, or even not at all.
4. Create "offspring" between each pair of two organisms from the working population by combining DNA from each parent. In our program, each set of parents will produce 2 offspring to drive the new generation, keeping the population levels constant.
5. Randomly mutate each individual's genes slightly. This ensures genetic diversity remains within the population.

At the end of this process (once a certain fitness or generation cap has been hit), the resulting population should be significantly more fit to the environment than in the initial population.

**However:** while this process can produce optimized solutions difficult for humans to design from the start, it's important to note that nothing in this algorithm guarantees a *perfectly* fit organism in the end.

## Implementation in Python

Now that we know how the algorithm itself will work, we can get to the code. You can either interpret this as an experiment in literate programming or as me being too lazy to write any explanation at all! Here's the (at least highly annotated) source:

```python
"""
helloevolve.py implements a genetic algorithm that starts with a base
population of randomly generated strings, iterates over a certain number of
generations while implementing 'natural selection', and prints out the most fit
string.
 
The parameters of the simulation can be changed by modifying one of the many
global variables. To change the "most fit" string, modify OPTIMAL. POP_SIZE
controls the size of each generation, and GENERATIONS is the amount of 
generations that the simulation will loop through before returning the fittest
string.
 
This program subject to the terms of the BSD license listed below.

Copyright (c) 2011 Colin Drake
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
 
import random
 
#
# Global variables
# Setup optimal string and GA input variables.
#
 
OPTIMAL     = "Hello, World"
DNA_SIZE    = len(OPTIMAL)
POP_SIZE    = 20
GENERATIONS = 5000
 
#
# Helper functions
# These are used as support, but aren't direct GA-specific functions.
#
 
def weighted_choice(items):
  """
  Chooses a random element from items, where items is a list of tuples in
  the form (item, weight). weight determines the probability of choosing its
  respective item. Note: this function is borrowed from ActiveState Recipes.
  """
  weight_total = sum((item[1] for item in items))
  n = random.uniform(0, weight_total)
  for item, weight in items:
    if n < weight:
      return item
    n = n - weight
  return item
 
def random_char():
  """
  Return a random character between ASCII 32 and 126 (i.e. spaces, symbols,
  letters, and digits). All characters returned will be nicely printable.
  """
  return chr(int(random.randrange(32, 126, 1)))
 
def random_population():
  """
  Return a list of POP_SIZE individuals, each randomly generated via iterating
  DNA_SIZE times to generate a string of random characters with random_char().
  """
  pop = []
  for i in xrange(POP_SIZE):
    dna = ""
    for c in xrange(DNA_SIZE):
      dna += random_char()
    pop.append(dna)
  return pop
 
#
# GA functions
# These make up the bulk of the actual GA algorithm.
#
 
def fitness(dna):
  """
  For each gene in the DNA, this function calculates the difference between
  it and the character in the same position in the OPTIMAL string. These values
  are summed and then returned.
  """
  fitness = 0
  for c in xrange(DNA_SIZE):
    fitness += abs(ord(dna[c]) - ord(OPTIMAL[c]))
  return fitness
 
def mutate(dna):
  """
  For each gene in the DNA, there is a 1/mutation_chance chance that it will be
  switched out with a random character. This ensures diversity in the
  population, and ensures that is difficult to get stuck in local minima.
  """
  dna_out = ""
  mutation_chance = 100
  for c in xrange(DNA_SIZE):
    if int(random.random()*mutation_chance) == 1:
      dna_out += random_char()
    else:
      dna_out += dna[c]
  return dna_out
 
def crossover(dna1, dna2):
  """
  Slices both dna1 and dna2 into two parts at a random index within their
  length and merges them. Both keep their initial sublist up to the crossover
  index, but their ends are swapped.
  """
  pos = int(random.random()*DNA_SIZE)
  return (dna1[:pos]+dna2[pos:], dna2[:pos]+dna1[pos:])
 
#
# Main driver
# Generate a population and simulate GENERATIONS generations.
#
 
if __name__ == "__main__":
  # Generate initial population. This will create a list of POP_SIZE strings,
  # each initialized to a sequence of random characters.
  population = random_population()
 
  # Simulate all of the generations.
  for generation in xrange(GENERATIONS):
    print "Generation %s... Random sample: '%s'" % (generation, population[0])
    weighted_population = []
 
    # Add individuals and their respective fitness levels to the weighted
    # population list. This will be used to pull out individuals via certain
    # probabilities during the selection phase. Then, reset the population list
    # so we can repopulate it after selection.
    for individual in population:
      fitness_val = fitness(individual)
 
      # Generate the (individual,fitness) pair, taking in account whether or
      # not we will accidently divide by zero.
      if fitness_val == 0:
        pair = (individual, 1.0)
      else:
        pair = (individual, 1.0/fitness_val)
 
      weighted_population.append(pair)
 
    population = []
 
    # Select two random individuals, based on their fitness probabilites, cross
    # their genes over at a random point, mutate them, and add them back to the
    # population for the next iteration.
    for _ in xrange(POP_SIZE/2):
      # Selection
      ind1 = weighted_choice(weighted_population)
      ind2 = weighted_choice(weighted_population)
 
      # Crossover
      ind1, ind2 = crossover(ind1, ind2)
 
      # Mutate and add back into the population.
      population.append(mutate(ind1))
      population.append(mutate(ind2))
 
  # Display the highest-ranked string after all generations have been iterated
  # over. This will be the closest string to the OPTIMAL string, meaning it
  # will have the smallest fitness value. Finally, exit the program.
  fittest_string = population[0]
  minimum_fitness = fitness(population[0])
 
  for individual in population:
    ind_fitness = fitness(individual)
    if ind_fitness <= minimum_fitness:
      fittest_string = individual
      minimum_fitness = ind_fitness
 
  print "Fittest String: %s" % fittest_string
  exit(0)
```

## Result
Here's an example of output generated by the script:

    Generation 0... Random sample: 'RE}36#qP'_u%'
    Generation 1... Random sample: '{z?.;7CEYy#g'
    Generation 2... Random sample: '0/5^aGk]yx1='
    Generation 3... Random sample: 'lP6]`HBUS|1='
    Generation 4... Random sample: 'l,iK%6{;<|Lk'
    Generation 5... Random sample: '0/5^aGk]y][j'
    ...
    ...
    Generation 4999... Random sample: 'HeClo, World'
    Fittest String: Hello, World
