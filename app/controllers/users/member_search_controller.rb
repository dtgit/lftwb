class Users::MemberSearchController < ApplicationController
  
  before_filter :login_required
  before_filter :setup
  
  def index
    if ((params[:country] != nil) || (params[:language] != nil) || (params[:prof_role] != nil || params[:name] != nil || params[:keywords] != nil))
    
      country = params[:country][:id]
      @selected_country = country.empty? ? nil : country.to_i
      
      lang = params[:language][:id]
      @selected_language = lang.empty? ? nil : lang.to_i
      
      prof_role = params[:prof_role][:id]
      @selected_prof_role = prof_role.empty? ? nil : prof_role.to_i
      
      name = params[:name]
      @selected_name = name.empty? ? nil : name.to_s
          
      keywords = params[:keywords]
      @selected_keywords = keywords.empty? ? nil : keywords.to_s
      
      query_enum1 = ""
      query_val1 = ""
      query_enum2 = ""
      query_val2 = ""
      quoted_words = Array.new   
      
      if !keywords.empty?
        keywords.scan(/"[^"]+"|\S+/).map do |s| 
          if s[0]!=34
            if query_enum1.empty? && query_val1.empty?
              query_enum1 = "value:" + s
              query_val1 = "svalue:" + s + " OR tvalue:" + s
            else
              query_enum1 += " OR value:" + s
              query_val1 += " OR svalue:" + s + " OR tvalue:" + s
            end
          else
            quoted_words.push(s)
          end
        end 
      end
         
      enum_array = Array.new
      vals_array = Array.new
      valt_array = Array.new
      
      quoted_words.each do |word|
        unquoted_word = word[1, word.length-2]
        split_words = unquoted_word.split(' ')
        temp_enum_string = ""
        temp_vals_string = ""
        temp_valt_string = ""
        split_words.each do |split_word|
          if temp_enum_string.empty?
            temp_enum_string = "value:" + split_word
          else
            temp_enum_string << " AND value:" + split_word
          end
          if temp_vals_string.empty?
            temp_vals_string = "svalue:" + split_word
          else
            temp_vals_string << " AND svalue:" + split_word
          end
          if temp_valt_string.empty?
            temp_valt_string = "tvalue:" + split_word
          else
            temp_valt_string << " AND tvalue:" + split_word
          end
        end
        enum_array.push(temp_enum_string)
        vals_array.push(temp_vals_string)
        valt_array.push(temp_valt_string)
      end
         
      if !enum_array.empty?
        enum_array.each do |enum|
          if !query_enum1.empty?
            query_enum1 << " OR ("
            query_enum1 << enum + ")"
          else
            query_enum1 = "("
            query_enum1 << enum + ")"
          end
        end
      end
         
      if !vals_array.empty?
        vals_array.each do |enum|
          if !query_val1.empty?
            query_val1 << " OR ("
            query_val1 << enum + ")"
          else
            query_val1 = "("
            query_val1 << enum + ")"
          end
        end
      end
          
      if !valt_array.empty?
        valt_array.each do |enum|
          if !query_val1.empty?
            query_val1 << " OR ("
            query_val1 << enum + ")"
          else
            query_val1 = "("
            query_val1 << enum + ")"
          end
        end
      end
        
      if !query_enum1.empty?
        tests = BagPropertyEnum.find_by_solr("#{query_enum1}").docs
        if !tests.empty?
          tests.collect do |x|
            if (((x.id).to_s != country) && ((x.id).to_s != lang) && ((x.id).to_s != prof_role))
              if query_enum2.empty?
                query_enum2 = (x.id).to_s
              else
                query_enum2 << ','
                query_enum2 << (x.id).to_s
              end
            end 
          end
        end
      end
        
      if !query_val1.empty?
        tests_v = BagPropertyValue.find_by_solr("#{query_val1}").docs
        if !tests_v.empty?
          tests_v.collect do |v|
            if query_val2.empty?
              query_val2 = (v.user_id).to_s
            else
              query_val2 << ','
              query_val2 << (v.user_id).to_s
            end
          end
        end
      end
        
      if country.empty?
        country = "select e.id from bag_property_enums e where bag_property_id = 11"
      end
      
      if lang.empty?
        lang = "select e.id from bag_property_enums e where bag_property_id = 6"
      end
      
      if prof_role.empty?
        prof_role = "select e.id from bag_property_enums e where bag_property_id = 1"
      end
      
      sql = "select * from users usrs where usrs.id in (select distinct u.id from users u " + 
            "join bag_property_values A on u.id = A.user_id and A.bag_property_enum_id IN (" + country + ") " +
            "join bag_property_values B on A.user_id=B.user_id and B.bag_property_enum_id IN (" + lang + ") " +
            "join bag_property_values C on A.user_id=C.user_id and C.bag_property_enum_id IN (" + prof_role + ") " 
          
      if !query_enum2.empty? && !query_val2.empty?
        sql << "join bag_property_values D on A.user_id=D.user_id and D.user_id in " 
        sql << "(select t.user_id from bag_property_values t where t.bag_property_enum_id in (" 
        sql << query_enum2
        sql << ") union select b.user_id from bag_property_values b where b.user_id in ("   
        sql << query_val2
        sql << ")) "   
      elsif !query_enum2.empty?
        sql << "join bag_property_values D on A.user_id=D.user_id and D.bag_property_enum_id in (" 
        sql << query_enum2
        sql << ") "   
      elsif !query_val2.empty?
        sql << "and u.id in (" 
        sql << query_val2
        sql << ") "       
      else
        # no sql to append 
      end
      
      sql << "and (u.first_name like ('#{name.lstrip.rstrip}%') OR u.last_name like ('#{name.lstrip.rstrip}%') OR u.login like ('#{name.lstrip.rstrip}%') " +
          "OR u.email like ('#{name.lstrip.rstrip}%'))) "
            
      sql << " ORDER BY usrs.first_name"
      puts "printing member search sql..."
      puts sql
      
      @results = User.find_by_sql(sql).paginate(:page => @page, :per_page => 20)
       
      flash[:notice] = @results.empty? ? _('Your search did not match any members on the website.') : nil
       
    end
    
    @country = BagPropertyEnum.find(:all, :conditions => ['bag_property_id = 11'], :order => "sort, name")
    @language = BagPropertyEnum.find(:all, :conditions => ['bag_property_id = 6'], :order => "sort, name")
    @prof_role = BagPropertyEnum.find(:all, :conditions => ['bag_property_id = 1'], :order => "sort, name")
    
    respond_to do |format|
          format.html { render }
          format.rss { render :layout => false }
    end
     
  end
  
  def setup
    @user = User.find_by_login(params[:user_id])
  end
end
