# 🎓 Master Thesis — The Potential for Capacity Expansion in Swedish Hydropower Plants📚

> Modeling capacity expansions using a linear deterministic optimization model, investigating different expansion locations during various year scenarios. 

---

## 🚀 Overview

Welcome to the code repository for my master’s thesis at Chalmers University of Technology. 

- 🔢 Optimization modeling  
- 🌊 Hydropower modeling
- 🧠 Algorithms 
- 📊 Data analysis  

The goal of the thesis is to **[state your research goal briefly]**, and this repo contains the full codebase and configuration needed to reproduce the experiments and results.

---

## 🛠️ Project Structure

```
📁 src/                  # Source code  
📁 results/              # Model outputs and figures  
📁 data/                 # Raw and processed datasets  
📁 notebooks/            # Jupyter/Pluto notebooks (exploratory work)  
📄 main.jl               # Entry point / runner script  
📄 Project.toml          # Julia environment file  
📄 README.md             # You're here!  
```

---

## ⚙️ Installation & Setup

> Tested with **Julia v1.9+** 🐍

1. Clone the repository:

```bash
git clone https://github.com/yourusername/your-thesis-project.git
cd your-thesis-project
```

2. Activate the Julia environment:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

3. (Optional) Set environment variable for data path:

```bash
export FORSA_DATA_PATH="/path/to/your/data"
```

---

## 🧪 Running the Project

To run the main simulation or analysis:

```julia
include("main.jl")
```

Or if using a custom runner:

```bash
julia src/runner.jl <arguments>
```

---

## 📊 Results & Figures

All outputs are saved in the `results/` folder:
- 📈 `*.csv` files: Data outputs  
- 🖼️ `*.png` / `*.pdf`: Plots and figures  
- 📁 Optional: Logs or diagnostic data  

---

## 💡 Techniques Used

| Technique | Description |
|----------|-------------|
| 📦 Modular design | Organized Julia modules for clarity and reuse |
| 🧮 Time-series modeling | Using real-world data over multiple years |
| 🧠 Machine learning | [e.g., Random Forests, XGBoost] (if applicable) |
| 🗂️ Data pipelines | Preprocessing raw hydrological data |
| 📈 Visualization | Clean plots using `Plots.jl`, `Makie.jl`, or `Gadfly.jl` |

---

## 📂 Data

Data used in this project is stored locally in the `/data` folder and is **not included** in this repo for size/privacy reasons.

If you’re from the university and want access, contact me via email below.

---

## 🧑‍🎓 About Me

👋 Hi! I'm *Your Name*, and this was my final thesis for my MSc in *Your Program* at *Your University*.

- 🌐 Website / LinkedIn: [your link here]  
- 📘 Thesis PDF: http://hdl.handle.net/20.500.12380/309590 

---

## 🤝 Acknowledgements

- 🧑‍🏫 Supervisor: *Prof. X*    

---

## ⭐️ If you find this useful...

Please consider giving this repo a ⭐️ — it helps visibility and shows support!
