require './calculator'

require "test/unit/assertions"
include Test::Unit::Assertions

# see https://github.com/cjheath/treetop
# to compile -> tt calculator_grammar.treetop -f

calculator = Calculator.new(tva: 20)

# ------------------------------------------------------------------
context = {
  source: "APP", # [APP|WEB]
  delivery: "PICKUP", # [CHRONO|PICKUP]
  preparation_amount_ttc: 300.00 
}

# standard configuration for a shop
assert_equal({ fix: 3.00, percentage: 20, fee: 63.00, payout: 187.00, tva: 50.00} , calculator.parse(context,"
TAUX=20%, FIX=3.00E
")[:value]) 

# standard configuration for a shop with pickup
assert_equal({ fix: 3.00, percentage: 5, fee: 18.00, payout: 232.00, tva: 50.00, rule: "si la livraison est PICKUP"}, calculator.parse(context,"
TAUX=20%, FIX=3.00E
si la livraison est PICKUP alors TAUX=5%, FIX=3.00E
")[:value])

# ------------------------------------------------------------------
context = {
  source: "APP", # [APP|WEB]
  preparation_amount_ttc: 300.00,
  preparation_amount_tva: 40.00  # if the TVA is not the default'one
}

# if more than one rule is valid, select the one that minimize epicery's fee 
assert_equal({ fix: 3.00, percentage: 15, fee: 48.00, payout: 202.00, tva: 50.00, rule: "si le montant de la commande excede 200.00E"}, calculator.parse(context,"
TAUX=20%, FIX=3.00E
si la livraison est PICKUP alors TAUX=5%, FIX=1.00E
si la commande est issue de APP alors TAUX=20%, FIX=2.00E
si le montant de la commande excede 200.00E alors TAUX=15%, FIX=3.00E
")[:value])

# a condition in a rule can use "et" & "ou" operators
assert_equal({ fix: 3.00, percentage: 10, fee: 33.00, payout: 217.00, tva: 50.00, rule: "si la commande est issue de APP et le montant de la commande excede 180.00E" }, calculator.parse(context,"
TAUX=20%, FIX=3.00E
si la commande est issue de APP,WEB alors TAUX=20%, FIX=2.00E
si la commande est issue de APP et le montant de la commande excede 180.00E alors TAUX=10%, FIX=3.00E
si le montant de la commande excede 200.00E alors TAUX=15%, FIX=3.00E
")[:value])