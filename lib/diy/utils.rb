module DIY
  module Utils
    class << self
      # 漂亮输出包的前十个内容
      def pp(pkt)
        pkt = pkt.content if pkt.kind_of?(DIY::Packet)
        return nil if pkt.nil?
        ( pkt[0..10] + "..." ).dump
      end
      
      def src_mac(pkt)
        pkt = pkt.content if pkt.kind_of?(DIY::Packet)
        pkt[6..11]
      end
      
      def dst_mac(pkt)
        pkt = pkt.content if pkt.kind_of?(DIY::Packet)
        pkt[0..5]
      end
    end
  end
end