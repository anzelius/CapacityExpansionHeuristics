# 🌊 Modeling Capacity Expansions in Swedish Hydropower Plants 🌊

## 🚀 Overview

Original model description: https://doi.org/10.1016/j.rser.2023.113406 developed by Ek Fälth, H.

This program has expanded the original model enabling modeling of capacity expansions. Further description with investigations can be found: http://hdl.handle.net/20.500.12380/309590 

Additionally since the second report release, the program has been refactored, enabling a modular design to easily run and add more custom:
- expansion methods / scenarios, supporting combinations
- prioritization of expansions
- grouping and sizing of each expansion step
- price profile scenarios, supporting combinations

Keywords: optimization modeling, hydropower modeling, capacity expansion, hydropower

---

## 🛠️ Project Design

Flow chart incoming ... 

---

## ⚙️ Installation & Setup

> Tested with **Julia v1.9+** 🐍

1. Clone the repository:

```bash
git clone https://github.com/anzelius/capacity_expansion.git
cd capacity_expansion
```

2. Activate the Julia environment:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

3. Install requirements

---

## 🧪 Running the Project

To run the main simulation or analysis:

```julia
include("main.jl")
```

---

## 📂 Data

Data used in this project is **not included** in this repo for privacy reasons.

---

## 🤝 Acknowledgements

- 🧑‍🏫 Supervisor: Hanna Ek Fälth

