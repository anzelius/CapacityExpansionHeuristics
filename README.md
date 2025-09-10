# 🌊 Modeling Capacity Expansions in Swedish Hydropower Plants 🌊

## 🚀 Overview

This program expands a hydropower optimization model to enable modelling of capacity expansions through installation of new turbines. Further description with investigations can be found: http://hdl.handle.net/20.500.12380/309590 

The original hydropower model was developed by Ek Fälth, H:
Article: https://doi.org/10.1016/j.rser.2023.113406
Github: https://github.com/hannaekfalth/Rivermodel-Public

This program has a modular design to easily run and add more custom:
- expansion methods / scenarios, supporting combinations
- prioritization of expansions
- grouping and sizing of each expansion step
- price profile scenarios, supporting combinations

---
## ⚙️ Specific setup for the report
The report investigates the "bottleneck" and "inflow" strategies which had the following configurations.
These configurations are the only ones that have been tested. Other settings included in the code have been included after the report and all of them may not have been fully tested yet. 

### Common: 

**river** = :All  
**start_datetime** = "2016-01-01T08", "2019-01-01T08", "2020-01-01T08"  
**end_datetime** = "2016-12-31T08", "2019-12-31T08", "2020-12-31T08"  
**objective** = "Profit"  
**model** = "Linear"   
**environmental_constraints_scenario** = "Dagens miljövillkor"    
**order_metric** = :HxD   
**strict_order** = N/A 
**order_grouping** = :percentile    
**order_basis** = :aggregated   
**theoretical** = false   
**price_profile_scenario** = :none  

### Renewable Scenario 

**price_profile_scenario** = :volatility   
**settings** = (price_factor = 1.1)

### Theoretical runs
**theoretical** = true   
**settings** = (peak_date="2016-01-02T08")

### Bottleneck:  
**expansion_strategy** = "Bottlenecks"    
**settings** = (percentile = 10:10:100)

### Inflow:  
**expansion_strategy** = "Match flow"  
**settings** = (percentile = 6.66:6.66:100, flow_match="LHQ", flow_scale=0.75)

---

## 📂 Data

Data used in this project is **not included** in this repo due to confidentiality.


