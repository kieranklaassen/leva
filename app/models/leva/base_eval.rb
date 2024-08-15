module Leva
  class BaseEval
    def evaluate(prediction, text_content)
      raise NotImplementedError, "Subclasses must implement the 'evaluate' method"
    end
  end
end