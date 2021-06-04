%% Wifi Data Analysis 

clear variables


wifidata = readtable('C:\Users\charl\AppData\Local\Temp\wifi_2019-03.csv');

wifidata.Building = categorical(wifidata.Building);
wifidata.Floor = categorical(wifidata.Floor);



G = findgroups(wifidata.Building, wifidata.Floor);  
numberofareas = max(G);
areas = splitapply( @(varargin) varargin, wifidata, G);
Width = width(wifidata);
        

for i = 1:numberofareas
    for j = 1:Width
        area{i}(:,j) = table(areas{i,j});
    end
end


for i = 1:numberofareas
area{1, i}.Properties.VariableNames{1} = 'time';
area{1, i}.Properties.VariableNames{2} = 'EventTime';
area{1, i}.Properties.VariableNames{3} = 'AssociatedClientCount';
area{1, i}.Properties.VariableNames{4} = 'AuthenticatedClientCount';
area{1, i}.Properties.VariableNames{5} = 'Uni';
area{1, i}.Properties.VariableNames{6} = 'Building';
area{1, i}.Properties.VariableNames{7} = 'Floor';
% area{1, i}.Properties.VariableNames{8} = 'Daynumber';
% area{1, i}.Properties.VariableNames{9} = 'Timeofday';

end




 %% Average Daily Profile for each meter for this particular month

% Fills in missing timestamp data

for i = 1:numberofareas
    TT{1,i} = table2timetable(area{1,i}(:,{'time', 'AssociatedClientCount'}));
    TT{1,i} = sortrows(TT{1, i},'time','ascend');
    TT{1,i} = unique(TT{1,i});
    TT{1,i} = rmmissing(TT{1,i});
    TT{1,i} = retime(TT{1,i},'regular', 'linear','TimeStep',minutes(5));
    TT{1,i} = timetable2table(TT{1,i});
    area2{1,i} = TT{1,i};
    area2{1,i}(:,3) = table(area{1,i}.Building(1));
    area2{1,i}(:,4) = table(area{1,i}.Floor(1));
    area2{1, i}.Properties.VariableNames{3} = 'Building';
    area2{1, i}.Properties.VariableNames{4} = 'Floor';


end

% uncomment commented sections for average profile for each day 

 for i = 1:numberofareas
      %DayNumber = weekday(meter2{1,i}.timestamp); 
 timeofDay = timeofday(area2{1,i}.time);
WeekEnd = isweekend(area2{1,i}.time);
%  
%  area2{1,i}.Daynumber = DayNumber;
 area2{1,i}.Timeofday = timeofDay;
 area2{1,i}.Weekend = WeekEnd;
%  
groups = findgroups(area2{1,i}.Weekend, area2{1,i}.Timeofday);
%  
 area2{1,i}.group = groups;
 l = height(area2{1,i});
%  
 time1 = datetime(2018,1,1,0,0,0);
 time2 = datetime(2018,1,1,23,55,0);
 time = time1:minutes(5):time2;
%  
%  
%  
%  for n = 1:7
%      for j = 1:l
%          if meter2{1,i}.Daynumber(j) == n
%              day{i,n}(j,:) = meter2{1,i}(j,:);  
%          end
%      end  
%  end
% 
%  
%  
%  for n = 1:7
%      day2{i,n} = groupsummary(day{i,n},{'group'},'mean','reading','IncludeMissingGroups',false);
%      day2{i,n}.Properties.VariableNames{3} = 'Average_Reading';
%  end

 Weekday = groupsummary(area2{1,i},{'group'},'mean','AssociatedClientCount','IncludeMissingGroups',false);
 Weekday.Properties.VariableNames{3} = 'Average_Reading';
%  
%  figure()  
%  plot(time, day2{i,1}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,2}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,3}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,4}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,5}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,6}.Average_Reading(2:end))
%  hold on
%  plot(time, day2{i,7}.Average_Reading(2:end))
%  xlabel('Time')
%  ylabel(['Consumption' meter2{1,i}.units_after_conversion(1)])
%  legend('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
%  title(['Average Daily Profile for'  meter2{1,i}.Serving(1)  '-'  meter2{1,i}.serving_revised(1)])
%      

% create average weekday and weekend profile
avg_weekday{1,i} = normalize(movavg(Weekday.Average_Reading(1:288),'simple',20),'range');

avg_weekend{1,i} = normalize(movavg(Weekday.Average_Reading(289:end),'simple',20),'range');


  figure(i)  
%   subplot(2,4,i)
 plot(time, Weekday.Average_Reading(1:288))
%  hold on
%  plot(time, Weekday.Average_Reading(289:end))
 xlabel('Time')
 ylabel('Device Count')
% legend('Weekday','Weekend')
 title(['Average Daily Profile for'  area2{1,i}.Building(1)  '-'  area2{1,i}.Floor(1)])
    

 end
 
