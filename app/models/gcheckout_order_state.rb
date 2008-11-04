class GcheckoutOrderState < ActiveRecord::Base
  def to_s
    self.title
  end
  def chargeable?
    self.title.eql?("CHARGEABLE")
  end
  def charged?
    self.title.eql?("CHARGED")
  end
end
