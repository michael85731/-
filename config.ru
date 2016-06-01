require "nokogiri"
require "open-uri"

def call(env)
  cities = get_data
  city_times = to_array(count(cities).sort_by{|city,value| value}.reverse)

  content = ERB.new(File.read("hw.html"))
  [200, {"content-type" => "text/html"}, [content.result(binding)]]
end

def get_data
  origin_url = "http://service.etax.nat.gov.tw/etwmain/front/ETW183W3?year=<year>&startMonth=<start_month>&endMonth=<end_month>"
  year = "105"
  start_month = "03"
  end_month = "04"
  
  all = []
  while(1)
  	real_url = origin_url.gsub("<year>",year).gsub("<start_month>",start_month).gsub("<end_month>",end_month)
    result = call_url(real_url)

    if result.nil?
      break
    else
      all = all + result

      #數字月份驗證
      start_month = start_month.to_i - 2
      end_month = end_month.to_i - 2

      #一年扣完後
      if start_month < 0
      	year = year.to_i - 1
      	start_month = 11
      	end_month = 12
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