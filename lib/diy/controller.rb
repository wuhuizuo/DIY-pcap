# encoding : utf-8

require 'timeout'
module DIY
  class Controller
    def initialize( client, server, offline, strategy)
      @client = client
      @server = server
      @offline = offline
      @strategy = strategy
      @before_send = nil
      @timeout = nil
    end
    
    def run
      client = @client
      server = @server
      
      @fail_count = 0
      start_time = Time.now
      #clear
      client.terminal
      server.terminal
      
      loop do
        begin
        pkts = @offline.nexts
        one_round( client, server, pkts )
        client, server = server, client
        rescue HopePacketTimeoutError, UserError, FFI::PCap::LibError => e
          DIY::Logger.warn( "Timeout: Hope packet is #{pkts[0].pretty_print} ") if e.kind_of?(HopePacketTimeoutError)
          @fail_count += 1
          begin
          @offline.next_pcap
          rescue EOFError
            client.terminal
            server.terminal
            break
          end
          client,server = @client, @server
        rescue EOFError
          client.terminal
          server.terminal
          break
        end
      end
      DRb.stop_service
      end_time = Time.now
      stats_result( end_time - start_time, @fail_count )
    end
    
    def one_round( client, server, pkts )
      @error_flag = nil
      @round_count = 0 unless @round_count
      @round_count += 1
      DIY::Logger.info "round #{@round_count}: (c:#{client.__drburi} / s:#{server.__drburi}) #{pkts[0].pretty_print}:(queue= #{pkts.size})"
      if pkts.size >= 10
        DIY::Logger.warn "queue size too big: #{pkts.size}, maybe something error"
      end
      server.ready do |recv_pkt|
        next if @error_flag # error accur waiting other thread do with it
        recv_pkt = Packet.new(recv_pkt)
        begin
          @strategy.call(pkts.first, recv_pkt, pkts)
        rescue DIY::StrategyCallError =>e
          DIY::Logger.warn("UserError Catch: " + e.inspect)
          e.backtrace.each do |msg|
            DIY::Logger.info(msg)
          end
          @error_flag = e
        end
      end
      client_send(client, pkts)
      wait_recv_ok(pkts)
      server.terminal
    end
    
    def client_send(client, pkts)
      if @before_send
        pkts = pkts.collect do |pkt| 
          content = pkt.content
          begin
            pkt.content = @before_send.call(content)
          rescue Exception => e
            DIY::Logger.warn("UserError Catch: " + error = BeforeSendCallError.new(e) )
            error.backtrace.each do |msg|
              DIY::Logger.info(msg)
            end
            raise error
          end
          pkt
        end
      end
      begin
        client.inject(pkts)
      rescue FFI::PCap::LibError =>e
        DIY::Logger.warn("SendPacketError Catch: " + e )
        raise e
      end
    end
    
    def before_send(&block)
      @before_send = block
    end
    
    def timeout(timeout)
      @timeout = timeout
    end
    
    def stats_result( cost_time, fail_count )
      DIY::Logger.info " ====== Finished in #{cost_time} seconds"
      DIY::Logger.info " ====== Total fail_count: #{fail_count} failures"
    end
    
    def wait_recv_ok(pkts)
      wait_until(@timeout ||= 10) do
        if @error_flag
          raise @error_flag
        end
        pkts.empty?
      end
    end
    
    def wait_until( timeout = 10, &block )
      Timeout.timeout(timeout, DIY::HopePacketTimeoutError.new("hope packet wait timeout after #{timeout} seconds") ) do
        loop do
          break if block.call
          sleep 0.1
        end
      end
    end
    
  end
end
  