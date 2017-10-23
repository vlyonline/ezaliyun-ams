# require 'ezaliyun_ams/version'
require 'openssl'
require 'base64'
require 'erb'
require 'net/https'
require 'json'
include ERB::Util

module EzaliyunAms
  class Configuration
    attr_accessor :access_key_secret, :access_key_id, :format, :region_id,
                  :version, :signature_method, :signature_version, :domain
    def initialize
      @access_key_secret ||= ''
      @access_key_id ||= ''
      @format ||= 'JSON'
      @region_id ||= 'cn-hangzhou'
      @version ||= '2016-08-01'
      @signature_method ||= 'HMAC-SHA1'
      @signature_version ||= '1.0'
      @domain ||= 'cloudpush.aliyuncs.com'
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def get_rs api_params
      public_params ={
          'Format' => configuration.format,
          'RegionId' => configuration.region_id,
          'Version' => configuration.version,
          'AccessKeyId' => configuration.access_key_id,
          'SignatureMethod' => configuration.signature_method,
          'Timestamp' => seed_timestamp,
          'SignatureVersion' => configuration.signature_version,
          'SignatureNonce' => seed_signature_nonce
      }
      public_params = public_params.merge api_params
      public_params['Signature'] = sign configuration.access_key_secret, public_params
      post_param(public_params).body
    end

    # 原生参数经过2次编码拼接成标准字符串
    def canonicalized_query_string(params)
      cqstring = ''

      # Canonicalized Query String/使用请求参数构造规范化的请求字符串
      # 按照参数名称的字典顺序对请求中所有的请求参数进行排序
      params = params.sort.to_h

      params.each do |key, value|
        if cqstring.empty?
          cqstring += url_encode"#{key}=#{url_encode(value)}"
        else
          cqstring += url_encode"&#{key}=#{url_encode(value)}"
        end
      end
      return  cqstring
    end

    # 生成数字签名
    def sign(key_secret, params)
      key = key_secret + '&'
      signature = 'POST' + '&' + url_encode('/') + '&' + canonicalized_query_string(params)
      digest = OpenSSL::Digest.new('sha1')
      sign = Base64.encode64(OpenSSL::HMAC.digest(digest, key, signature))
      # url_encode(sign.chomp) # 通过chomp去掉最后的换行符 LF
      sign.chomp # 通过chomp去掉最后的换行符 LF
    end

    # 生成短信时间戳
    def seed_timestamp
      Time.now.utc.strftime("%FT%TZ")
    end

    # 生成短信唯一标识码，采用到微秒的时间戳
    def seed_signature_nonce
      Time.now.utc.strftime("%Y%m%d%H%M%S%L")
    end

    def post_param params
      uri = URI('https://' + configuration.domain)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        request = Net::HTTP::Post.new uri
        request.set_form_data params
        # request.body = params.to_json
        http.request request # Net::HTTPResponse object
      end
    end


    # ------各种接口从这开始------
    # APP概览列表
    def ListSummaryApps
      api_params = {
          'Action' => __method__.to_s
      }
      get_rs api_params
    end

    # ------推送相关接口
    # 推消息给Android设备
    def PushMessageToAndroid app_key, target, target_value, title, body
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'Target' => target,
          'TargetValue' => target_value,
          'Title' => title,
          'Body' => body
      }
      get_rs api_params
    end

    # 推消息给IOS设备
    def PushMessageToiOS app_key, target, target_value, title, body
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'Target' => target,
          'TargetValue' => target_value,
          'Title' => title,
          'Body' => body
      }
      get_rs api_params
    end

    # 推通知给Android设备
    def PushNoticeToAndroid app_key, target, target_value, title, body, ext_parameters = nil
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'Target' => target,
          'TargetValue' => target_value,
          'Title' => title,
          'Body' => body,
          'ExtParameters' => ext_parameters
      }
      if !ext_parameters.nil? then api_params['ExtParameters'] = ext_parameters end
      get_rs api_params
    end

    # 推通知给IOS设备
    def PushNoticeToiOS app_key, target, target_value, apns_env, title, body, ext_parameters = nil
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'Target' => target,
          'TargetValue' => target_value,
          'ApnsEnv' => apns_env,
          'Title' => title,
          'Body' => body
      }
      if !ext_parameters.nil? then api_params['ExtParameters'] = ext_parameters end
      get_rs api_params
    end

    # 推送高级接口  未完成
    def Push app_key, other_hash
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key
      }
      api_params.merge! other_hash
      get_rs api_params
    end

    # 取消定时推送任务
    def CancelPush app_key, message_id
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'MessageId' => message_id
      }
      get_rs api_params
    end

    # ------查询相关接口
    # 查询推送列表
    def ListPushRecords app_key, start_time, end_time, push_type=nil, page=nil, page_size=nil
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'StartTime' => start_time,
          'EndTime' => end_time,
          'PushType' => push_type,
          'Page' => page,
          'PageSize' => page_size
      }
      if !push_type.nil? then api_params['PushType'] = push_type end
      if !page.nil? then api_params['Page'] = page end
      if !page_size.nil? then api_params['PageSize'] = page_size end
      get_rs api_params
    end

    # APP维度推送统计
    def QueryPushStatByApp app_key, start_time, end_time, granularity
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'StartTime' => start_time,
          'EndTime' => end_time,
          'Granularity' => granularity
      }
      get_rs api_params
    end

    # 任务维度推送统计
    def QueryPushStatByMsg app_key, message_id
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'MessageId' => message_id
      }
      get_rs api_params
    end

    # 设备新增与留存
    def QueryDeviceStat app_key, start_time, end_time, device_type, query_type
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'StartTime' => start_time,
          'EndTime' => end_time,
          'DeviceType' => device_type,
          'QueryType' => query_type
      }
      get_rs api_params
    end

    # 去重设备统计
    def QueryUniqueDeviceStat app_key, start_time, end_time
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'StartTime' => start_time,
          'EndTime' => end_time
      }
      get_rs api_params
    end

    # 查询设备详情
    def QueryDeviceInfo app_key, device_id
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'DeviceId' => device_id
      }
      get_rs api_params
    end

    # 批量检查设备有效性
    def CheckDevices app_key, device_ids
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'DeviceIds' => device_ids
      }
      get_rs api_params
    end

    # ------TAG相关接口
    # 绑定TAG
    def BindTag app_key, client_key, key_type, tag_name
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'ClientKey' => client_key,
          'KeyType' => key_type,
          'TagName' => tag_name
      }
      get_rs api_params
    end

    # 查询TAG
    def QueryTags app_key, client_key, key_type
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'ClientKey' => client_key,
          'KeyType' => key_type
      }
      get_rs api_params
    end

    # 解绑TAG
    def UnbindTag app_key, client_key, key_type, tag_name
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'ClientKey' => client_key,
          'KeyType' => key_type,
          'TagName' => tag_name
      }
      get_rs api_params
    end

    # TAG列表
    def ListTags app_key, client_key, key_type, tag_name
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key
      }
      get_rs api_params
    end

    # 删除TAG
    def RemoveTag app_key, tag_name
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'TagName' => tag_name
      }
      get_rs api_params
    end

    # ------别名相关接口
    # 绑定别名
    def BindAlias app_key, device_id, alias_name
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'DeviceId' => device_id,
          'AliasName' => alias_name
      }
      get_rs api_params
    end

    # 查询别名
    def QueryAliases app_key, device_id
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'DeviceId' => device_id
      }
      get_rs api_params
    end

    # 解绑别名
    def UnbindAlias app_key, device_id, unbind_all = nil, alias_name = nil
      api_params = {
          'Action' => __method__.to_s,
          'AppKey' => app_key,
          'DeviceId' => device_id
      }
      if !unbind_all.nil? then api_params['UnbindAll'] = unbind_all end
      if !alias_name.nil? then api_params['AliasName'] = alias_name end
      get_rs api_params
    end

  end
end