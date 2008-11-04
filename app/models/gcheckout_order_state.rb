class GcheckoutOrderState < ActiveRecord::Base

  def to_s
    "#{title}"
  end

  def chargeable?
    title.eql?("CHARGEABLE")
  end

  def charged?
    title.eql?("CHARGED")
  end
end
