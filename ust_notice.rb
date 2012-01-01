# coding: utf-8
require 'rubygems'
require 'net/http'
require 'json'
require 'yaml'
require 'pony'

root_dir = File.dirname(__FILE__)
config_file = "#{root_dir}/config.yml"
last_stat_file = "#{root_dir}/last_stat.yml"

# 設定ファイル読み込み
config = YAML.load_file(config_file)
channels = config["channels"]
dev_key = config["key"]

# 前回のステータスファイルを読み込み
last_stat = YAML.load_file(last_stat_file)

# チャンネル巡回
channels.each do |channel|
    # ステータス取得
    http = Net::HTTP.new('api.ustream.tv')
    response = http.get("/json/channel/#{channel}/getValueOf/status?key=#{dev_key}")
    result = JSON.parse(response.body)

    # 前回のステータス取得
    if not last_stat
        last_stat = {channel => "offline"}
    elsif not last_stat[channel]
        last_stat[channel] = "offline"
    end

    # ライブ配信が始まってたら
    if result['results'] == 'live'
        if last_stat[channel] == 'offline'
            # メール通知
            Pony.mail(:from => 'Ustream notice',
                      :to => config['mail_to'],
                      :subject => "Ust配信開始のお知らせ",
                      :body => "#{channel} が配信を開始しました。",
                      :charset => "UTF-8",
                      :via => :smtp,
                      :via_options => {
                        :enable_starttls_auto => true,
                        :address => config['mail_address'],
                        :port => config['mail_port'],
                        :user_name => config['mail_user_name'],
                        :password => config['mail_password'],
                        :authentication => :plain,
                        :domain => config['mail_domain']
                        }
                     )
        end
    end
    last_stat[channel] = result['results']
end

open(last_stat_file, "w") do |f|
    YAML.dump(last_stat, f)
end

