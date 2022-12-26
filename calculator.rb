require 'rubygems'
require 'treetop'
require './calculator_grammar'

# A domain specific language to describe how to compute epicery's fees
# the language follows the following grammar
# default_paramaters
# (if condition then set_parameters)*
class Calculator

    def initialize(tva: 20)
        @parser = CalculatorGrammarParser.new
        @tva = tva / 100.0
    end

    def parse(context, input_text)
        result = { input_text: input_text, context: context }
        if parse_data = @parser.parse(input_text.strip)
            result.merge!(value: choose(context, parse_data.value(context)))
        else
            result[:error] = { line: @parser.failure_line, column: @parser.failure_column, reason: @parser.failure_reason }
            puts "Oups:" << result[:error].collect {|k,v| "#{k}=#{v}"}.join(", ")
        end
        result
    end

    private

    def choose(context, list_parameters)
        best_parameters = list_parameters.inject(nil) do |bp, parameters|
            fee = compute_fee(context, parameters)
            (bp.nil? || fee < bp[:fee]) ? parameters.merge(fee: fee) : bp
        end
        fee = best_parameters[:fee]
        preparation_amount_ttc = context[:preparation_amount_ttc]
        tva = preparation_amount_ttc - (preparation_amount_ttc / (1.0 + @tva)).round(2)
        payout = (preparation_amount_ttc - fee - tva).round(2)
        raise "rounding issue?" unless preparation_amount_ttc == tva + payout + fee
        best_parameters.merge!(tva: tva, payout: payout)
    end

    def compute_fee(context, parameters)
        parameters[:fix] + ((parameters[:percentage] / 100.0) * context[:preparation_amount_ttc]).round(2)
    end

end

