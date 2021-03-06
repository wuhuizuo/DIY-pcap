require 'spec_helper'

describe DIY::Utils do
  it "#pp" do
    DIY::Utils.pp('a' * 100).should match(/\(100 sizes\)/)
  end
  
  it "#pp parse error" do
    badtcp = File.open('helper/badtcp.dat', 'rb') { |io| io.read }
    lambda { puts DIY::Utils.pp(badtcp) }.should_not raise_error
  end
  
  it "#pp false" do
    DIY::Utils.pp('a' * 100, false).should_not match(/\(100 sizes\)/)
  end
  
  it "#src_mac" do
    DIY::Utils.src_mac( 'a' * 100 ).should == "a" * 6
  end

  it "#dst_mac" do
    DIY::Utils.dst_mac( 'a' * 100 ).should == "a" * 6
  end
  
  it "#pp_mac" do
    DIY::Utils.pp_mac( "\377" * 6 ).should == "ff:ff:ff:ff:ff:ff"
  end
  
  it "#print_backtrace" do
    begin
      raise 
    rescue 
      lambda { DIY::Utils.print_backtrace($!) }.should_not raise_error
    end
  end

end