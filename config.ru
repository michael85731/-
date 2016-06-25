require "nokogiri"
require "open-uri"
require "json"

def call(env)
  city_times = check_file
  content = ERB.new(File.read("hw.html"))
  [200, {"content-type" => "text/html"}, [content.result(binding)]]
end

def check_file
  if File.exist?('result')
    #如果現存資料老舊也要更新
    if check_data
      data = JSON.parse(File.read('result'))
      data["data"]
    else
      get_data
    end
  else
    get_data
  end
end

def check_data
  File.read('result'){|file_data|
    raw_data = JSON.parse(file_data)
    last_update = raw_data["update"]
    last_update_year = last_update.to_s.slice(0,4).to_i
    last_update_month = last_update.to_s.slice(3,2).to_i

    #只要大於今年 或 上次更新月份 < 現在月份 且 現在月份為奇數 就要更新
    Time.new.year > last_update_year or (Time.new.month.odd? and Time.new.month > last_update_month)
  }
end

def get_data
  cities = get_url_data
  city_times = to_array(count(cities).sort_by{|city,value| value}.reverse)
  write_data(city_times)
  city_times
end

def get_url_data
  origin_url = "http://service.etax.nat.gov.tw/etwmain/front/ETW183W3?year=<year>&startMonth=<start_month>&endMonth=<end_month>"
  year = "100" #100
  start_month = "01" #01
  end_month = "02" #02
  
  all = []
  while(1)
  	real_url = origin_url.gsub("<year>",year).gsub("<start_month>",start_month).gsub("<end_month>",end_month)
    result = call_url(real_url)

    if result.nil?
      break #沒資料後退出迴圈
    else
      all = all + result

      #數字月份驗證
      start_month = start_month.to_i + 2
      end_month = end_month.to_i + 2

      #一年加完後
      if start_month > 11
      	year = year.to_i + 1
      	start_month = 1
      	end_month = 2
      end

      #改回字串
      year = year.to_s

      if start_month < 10
      	start_month = "0" + start_month.to_s
      else
      	start_month = start_month.to_s
      end

      if end_month < 10
      	end_month = "0" + end_month.to_s
      else
      	end_month = end_month.to_s
      end 
           
    end
  end
  all
end

def write_data(data)
  file = File.open('result','w'){|f|
    
    #讓month格式固定為"00"
    month = Time.new.month
    if month < 10
      month = "0" + month.to_s
    end

    f.puts "{\"update\":\"#{Time.new.year.to_s + month}\",\"data\":\"#{data.to_s.gsub("\"","\'")}\"}"
  }
end

def count(cities)
  city_times = {}
  cities.each{|city|
  if city_times[city].nil?
 	  city_times[city] = 1
 	else
 	  city_times[city] += 1
 	end
  }
  city_times
end

def to_array(arg)
  new_array = []
  arg.each{|key, value|
    new_array << key
    new_array << value
  }
  new_array.each_slice(2).to_a
end

def call_url(url)
  raw_data = Nokogiri::HTML(open(url)) #用open-uri這個library抓進url的資料

  if !(raw_data.css(".table_a tr").empty?)
  	temp = []
    raw_data.css(".table_a tr").each{|raw|
      unless raw.css("td").at(3).nil?
        temp << raw.css("td").at(3).to_s.slice(4,3)
      end
    }
  end
  temp
end

run self