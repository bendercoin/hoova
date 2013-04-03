$LOAD_PATH.unshift(File.expand_path('lib/'))
$LOAD_PATH.unshift(File.expand_path('lib/restclient/lib/'))
$LOAD_PATH.unshift(File.expand_path('lib/bitcoin-client/lib/'))

require 'hoova'
require 'hoova_splash'
require 'json'
class HoovaGUI < Shoes
  url '/', :splash # Production
  #url '/', :start # Change start to point to where you want to go for dev
  url '/wallet_sweep_setup', :wallet_sweep_setup
  url '/start', :start

  def splash
    extend HoovaSplash
    show_splash
  end

  def start
    visit '/wallet_sweep_setup'
  end

  def wallet_sweep_setup
    @sweeping_loop_delay = 60

    background "./static/menu-gray.png"
    background "./static/menu-top.png", :height => 50
    background "./static/menu-left.png", :top => 50, :width => 55
    background "./static/menu-right.png", :right => 0, :top => 50, :width => 55
    image "./static/menu-corner1.png", :top => 0, :left => 0
    image "./static/menu-corner2.png", :right => 0, :top => 0

    @job_config = load_job

    rect 0, 0, 640, 40
    background "./hoova-bg.png"
    caption strong("Setup and Turn on the Vacuum"), :align => 'right', :stroke => white, :margin => 12
    caption strong("Sweep FROM this Wallet"), :margin => [0, 60], :align => 'center'

    stack :width => 640, :margin => [150, 10] do


      flow do
        stack :width => 100 do
          para strong 'Username: '
        end
        stack :width => 100 do
          @rpc_username = edit_line @job_config['rpc_username']
        end
      end

      flow do
        stack :width => 100 do
          para strong 'Password: '
        end
        stack :width => 100 do
          @rpc_password = edit_line @job_config['rpc_password']
        end
      end

      flow do
        stack :width => 100 do
          para strong 'Host: '
        end
        stack :width => 100 do
          @rpc_host = edit_line @job_config['rpc_host']
        end
      end

      flow do
        stack :width => 100 do
          para strong 'Port: '
        end

        stack :width => 100 do
          @rpc_port = edit_line @job_config['rpc_port']
        end
      end

      flow do
        stack :width => 100 do
          para strong 'SSL: '
        end

        stack :width => 100 do
          @rpc_ssl = list_box :items => [true, false], :choose => @job_config['rpc_ssl']
        end
      end
    end
    stack :width => 640, :margin => [0, 10] do
      caption strong("Sweep INTO This Bitcoin Address"), :margin => [0], :align => 'center'
      flow :width => '100%', :margin => [0, 10] do
        stack :width => '50%', :margin => [100] do
          para "Destination Bitcoin Address:"
        end
        stack :width => '50%', :margin => [0] do
          @destination_address = edit_line @job_config['destination_btc_address'], :width => 275
        end

        stack :width => '100%', :margin => [205] do
          button "Save Job Configuration" do
            save_job
          end
        end
      end
    end
    caption strong("ACTIONS"), :margin => [0, 10], :align => 'center'
    @actions_buttons = flow :width => '100%', :margin => [0, 10] do
      button "Sweep Once", :margin => [180] {sweep('once')}
      @sweep_forever_button = button "Sweep Forever", :margin => [20] {sweep('forever')}
    end
  end

  def load_job
    return JSON.parse(IO.read('job.json'))
  end

  def save_job
    job_config = {
        'rpc_username' => @rpc_username.text,
        'rpc_password' => @rpc_password.text,
        'rpc_host' => @rpc_host.text,
        'rpc_port' => @rpc_port.text,
        'rpc_ssl' => @rpc_ssl.text,
        'destination_btc_address' => @destination_address.text
    }

    File.open("job.json", "w") do |f|
      f.write(job_config.to_json)
    end
  end


  def sweep(how)

    @actions_buttons.hide
    @p = progress :width => 0.75, :margin => [140]
    animate 50 do |i|
      @p.fraction = (i % 100) / 100.0
    end

    case how
      when 'forever'
        @sweeping_loop = every(@sweeping_loop_delay) { trigger_sweep }
    end

    @sweep_counter = 0
    setup_sweep_status_text

    @stop_sweeping_button = button "Stop Sweeping Every #{@sweeping_loop_delay} Seconds",
                                   :margin => [170] do
      stop_sweeping
    end

    # Setup the Source
    # CRITICAL TODO - DO VALIDATION CHECK TO CATCH STUPID ERRORS
    # Do a "Ping" type check
    # TODO allow setting of txfee in settings and passing in on wallet instantiation
    @source = Hoova::BitcoinWallet.new(@rpc_username.text, @rpc_password.text, @rpc_host.text, @rpc_port.text, @rpc_ssl.text)

    # CRITICAL TODO - DO VALIDATION CHECK TO CATCH STUPID ERRORS
    # Do a check on address. Warn if not a valid btc address
    # Warn if this is a testnet address
    # Confirm the address with a ARE YOU SURE THIS ADDR IS CORRECT?
    @destination = Hoova::BitcoinAddress.new(@destination_address.text.strip)

    trigger_sweep

    case how
      when 'once'
        stop_sweeping
        setup_sweep_status_text
        set_sweep_status_text(@last_sweep_result)
    end


  rescue Errno::ECONNREFUSED => e
    stop_sweeping
    alert ('Error: Wallet Unreachable. Connection Refused.')
  rescue Unauthorized
    stop_sweeping
    alert ('Error: Invalid Username or Password.')
  rescue InvalidWallet
    stop_sweeping
    alert ('Error: Invalid Wallet, Check your Settings.')
  rescue ConnectionTimeout
    stop_sweeping
    alert ('Error: Could not reach Wallet, Check your Settings.')
  end

  def setup_sweep_status_text
    @sweep_counter = 0
    if @sweep_status_text
      @sweep_status_text.remove
    end

    @sweep_status_text = para "", :margin => [140]
  end

  def set_sweep_status_text(message="")
    @sweep_status_text.replace strong("Sweep # #{@sweep_counter += 1} Result: #{message}\n")
  end

  def stop_sweeping
    @sweeping_loop.stop unless @sweeping_loop.nil?
    @sweep_status_text.remove
    @stop_sweeping_button.remove
    @p.remove
    @actions_buttons.show
  end


  def trigger_sweep
    @last_sweep_result = Hoova::Sweeper.new(@source, @destination).sweep_once
    set_sweep_status_text(@last_sweep_result)
  end

end

Shoes.app :width => 640, :height => 520
