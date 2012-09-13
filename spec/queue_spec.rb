require 'spec_helper'
describe DIY::Queue do
  
  before(:each) do
    @device_name = FFI::PCap.dump_devices[0][0]
    @live = FFI::PCap::Live.new(:dev=>@device_name, :handler => FFI::PCap::Handler, :promisc => true)
    @pcap_name = "../simple/pcaps/gre.pcap"
    @offline = DIY::Offline.new(@pcap_name)
  end
  
  it "#next_send_pkt" do
    $SERVER = nil
    q = DIY::Queue.new(@offline)
    q.stub(:wait_until).and_return(true)
    q.stub(:wait_for_seconds).and_return(nil)
    q.next_send_pkt.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt1' ) )
    pkt1 = q.instance_variable_get("@expect_recv_queue")[0][0]
    pkt2 = q.instance_variable_get("@expect_recv_queue")[1][0]
    q.instance_variable_get("@expect_recv_queue").size.should == 2
    pkt1.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    pkt2.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt3' ) )
    q.instance_variable_set("@expect_recv_queue", [])
    q.next_send_pkt.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt4' ) )
    q.instance_variable_get("@expect_recv_queue").should == []
    lambda { loop { q.next_send_pkt } }.should raise_error
  end
  
  it "#next_send_pkt server" do
    $SERVER = true
    q = DIY::Queue.new(@offline)
    q.stub(:wait_until).and_return(true)
    q.stub(:wait_for_seconds).and_return(nil)
    q.next_send_pkt.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    q.instance_variable_get("@expect_recv_queue")[0][0].should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt1' ) ) 
    q.instance_variable_set("@expect_recv_queue", [])
    q.next_send_pkt.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt3' ) )
    q.instance_variable_get("@expect_recv_queue")[0][0].should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt4' ))
    q.instance_variable_get("@expect_recv_queue")[1][0].should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt5' ))
    $SERVER = nil
  end
  
  it "#comein? server" do
    $SERVER = true
    q = DIY::Queue.new(@offline)
    q.stub(:wait_for_seconds).and_return(nil)
    pkt =  File.read( File.join( File.dirname(__FILE__), 'helper/pkt1' ) )
    pkt2 =  File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    q.set_first_gout(pkt).should == pkt[6..11]
    q.comein?(pkt).should == true
    q.comein?(pkt2).should == false
    $SERVER = nil
  end
  
  it "#peek #pop" do
    q = DIY::Queue.new(@offline)
    q.stub(:wait_until).and_return(true)
    q.stub(:wait_for_seconds).and_return(nil)
    q.next_send_pkt
    q.peek.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    q.pop.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    q.peek.should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt3' ) )
    q.pop
    q.peek.should == nil
  end
  
  it "#delete" do
    q = DIY::Queue.new(@offline)
    q.stub(:wait_until).and_return(true)
    q.stub(:wait_for_seconds).and_return(nil)
    q.next_send_pkt
    q.delete(File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )).should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
    q.pop
    q.peek.should == nil
  end
  
  it "#delete_at" do
    q = DIY::Queue.new(@offline)
    q.stub(:wait_until).and_return(true)
    q.stub(:wait_for_seconds).and_return(nil)
    q.next_send_pkt
    q.delete_at(0).should == File.read( File.join( File.dirname(__FILE__), 'helper/pkt2' ) )
  end

end