# 阿里云移动推送

用于阿里云和移动推送服务，就是APP消息和通知推送。

需要预先准备以下几个参数：
* AccessKeyId : 阿里云接入 ID， 在阿里云控制台申请获取。
* AccessKeySecret :  阿里云接入密钥，在阿里云控制台申请获取。
* AppKey : 分为IOS和安卓，不需要入配置，但是执行推送时需要写入参数，可以写入全局配置。
## 安装

添加ezaliyun-ams到 Gemfile:

```ruby
gem 'ezaliyun-ams'
```

然后执行:

    $ bundle

或者直接在命令行执行:

    $ gem install ezaliyun-ams

## 配置
### 普通配置
1、引入文件
```ruby
$ require 'ezaliyun-ams'
```
2、配置
```ruby
$ EzaliyunAms.configure do |config|
    config.access_key_secret = ACCESS_KEY_SECRET # 阿里云接入密钥，在阿里云控制台申请
    config.access_key_id = ACCESS_KEY_ID         # 阿里云接入 ID, 在阿里云控制台申请
  end
```
### rails配置
在 Rails 应用目录 config/initializers/ 下创建脚本文件 ezaliyun-ams.rb，在文件中加入以下内容：
```ruby
EzaliyunAms.configure do |config|
  config.access_key_secret = ACCESS_KEY_SECRET # 阿里云接入密钥，在阿里云控制台申请
  config.access_key_id = ACCESS_KEY_ID         # 阿里云接入 ID, 在阿里云控制台申请
  config.format = 'JSON'                       # 这一行可以不写，我默认的使用JSON，如果需要还可以使用XML
end
```
### 使用
* 因为推送接口比较多，所以接口实现部分我全部都是按[官方文档OpenAPI2.0](https://help.aliyun.com/document_detail/48038.html?spm=5176.7848062.6.591.8bmVPX) 来实现的，如果有需要请参考官方文档来使用，以下是本GEM包对接口的实现规则。
* 比如官方文档中[推通知给Android设备](https://help.aliyun.com/knowledge_detail/48087.html?spm=5176.7848064.2.3.qPD6kV),英文名叫PushNoticeToAndroid，
参数分别为（从上到下）Action、AppKey、Target、TargetValue、Title、Body、ExtParameters ,那么我的实现如下（只关注方法名和参数，过程省略）
```ruby
def PushNoticeToAndroid app_key, target, target_value, title, body, ext_parameters = nil
  ...
end
```

* 也就是说，方法名和官方给出的英文命名是一致的，
* Action参数不用写，我已直接在内部引用了方法名，其它参数按文档顺序从上到下（从Action后的一个参数开始）先后引入到方法
* 非必须参数（除了‘推通知给iOS设备’中的Title）可以不写
###### 代码示例
```ruby
EzaliyunAmsPushNoticeToAndroid 参数1, 参数2, 参数3, 参数4, 参数5
```
参数1对应了AppKey, 参数2对应了Target，参数3对应了TargetValue，参数4对应了Title，参数5对应了Body，如果需要使用到ExtParameters则再加一个参数即可

## 注意
* 建议使用时进行二次封装，因为接口实在太多，所以全部都是基础实现
* 安卓的APPKEY和IOS和不一样，调用接口时一定要注意
* 使用时不需要考虑公共参数，内部已经处理
* 要注意一点的是在[推通知给iOS设备](https://help.aliyun.com/knowledge_detail/48088.html?spm=5176.7848064.2.4.JzYMK0)里面，
Title参数是非必须参数，但是考虑到实际使用情况（偷懒）我这里实现时变成了必须参数，在使用时第5个参数一定要传，不想写可以传个''进来
* 暂时没有做异常抛出
* 高级推送接口实现如下,Action不用传，第一个参数是AppKey,第二个参数是个哈希，请传哈希，哈希内参数请参照[推送高级接口文档](https://help.aliyun.com/knowledge_detail/48089.html?spm=5176.7848064.2.5.pKk2ko)
```ruby
def Push app_key, other_hash
    api_params = {
      'Action' => __method__.to_s,
      'AppKey' => app_key
    }
    api_params.merge! other_hash
    ......
end
```
##### 这个Gem是本人第一个Gem，本人还是ruby新手，有任何问题或者其它事情都可以email我 vlyonline@163.com