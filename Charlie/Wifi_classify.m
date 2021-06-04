%% Wi-Fi Cluster/Classify 


%% Import the Data and Change Strings to Categories

clear all

wifidata = []; %INSERT DATAFILE readtable('C:\Users\charl\AppData\Local\Temp\wifi_2020-02.csv');

wifidata.Building = categorical(wifidata.Building);
wifidata.Floor = categorical(wifidata.Floor);


%% Split and Plot the Data (based on 'name'/MeterID)


% finds the new number of meters in the data 
G = findgroups(wifidata.Building, wifidata.Floor);  
numberofareas = max(G);


% creates a cell that contains the indidual columns of data for each meter
areas = splitapply( @(varargin) varargin, wifidata, G);


% calculates the number of columns in the data 
Width = width(wifidata);


% creates a cell that contains all of the information for each cell for
% training (creates a training set)
for i = 1:numberofareas
    for j = 1:Width
        area{1,i}(:,j) = table(areas{i,j});
    end
end  



%%

% assigns the appropraiet variable names to all of the meter tables

for i = 1:numberofareas
    area{1, i}.Properties.VariableNames{1} = 'time';
    area{1, i}.Properties.VariableNames{2} = 'EventTime';
    area{1, i}.Properties.VariableNames{3} = 'AssociatedClientCount';
    area{1, i}.Properties.VariableNames{4} = 'AuthenticatedClientCount';
    area{1, i}.Properties.VariableNames{5} = 'Uni';
    area{1, i}.Properties.VariableNames{6} = 'Building';
    area{1, i}.Properties.VariableNames{7} = 'Floor';
   
end




%% Average Daily Profile for each meter for this particular month

% fill out any missing parts to data

for i = 1:length(area)
TT{1,i} = table2timetable(area{1,i});
TT{1,i} = sortrows(TT{1, i},'time','ascend');
TT{1,i} = unique(TT{1,i});
TT{1,i} = rmmissing(TT{1,i});
TT{1,i} = retime(TT{1,i},'regular', 'previous','TimeStep',minutes(5));
end



% converts the timetable back to a table
for i = 1:length(area)
area2{1,i} = timetable2table(TT{1,i});
end




% fills out missing data points, configures average daily profile for a
% weekday and for weekend that is normalised and smoothed out 

 for i = 1:length(area)
      DayNumber = weekday(area2{1,i}.time); 
 timeofDay = timeofday(area2{1,i}.time);
 WeekEnd = isweekend(area2{1,i}.time);
 
 area2{1,i}.Weekend = WeekEnd;
 area2{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(area2{1,i}.Weekend, area2{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 area2{1,i}.group = groups;
 l = height(area2{1,i});
 
 % constructs a time variable for plotting purposes
 time1 = datetime(2018,1,1,0,0,0);
 time2 = datetime(2018,1,1,23,55,0);
 time = time1:minutes(5):time2;
 

 Weekday_train = groupsummary(area2{1,i},{'group'},'mean','AssociatedClientCount','IncludeMissingGroups',false);
 Weekday_train.Properties.VariableNames{3} = 'Average_Reading';
 

%  figure(i)  
%  plot(time, Weekday.Average_Reading(1:144))
%  xlabel('Time')
%  ylabel('Energy Consumption')
%  title(['Average Daily Profile for'  meter2{1,i}.serving_revised(1)  '-'  meter2{1,i}.Serving(1)])
%     

% creates normalised and normalised weekday and weekend profiles
 
avg_weekday_norm{i,1} = normalize(movavg(Weekday_train.Average_Reading(1:288),'simple',20),'range');
avg_weekday{i,1} = movavg(Weekday_train.Average_Reading(1:288),'simple',20);

avg_weekend_norm{i,1} = normalize(movavg(Weekday_train.Average_Reading(289:end),'simple',20),'range');
avg_weekend{i,1} = movavg(Weekday_train.Average_Reading(289:end),'simple',20);


 end
 





%% classification

% load wifi classification network and classify each meter

load('wifi_class_net.mat')

wifi_classify_data = avg_weekday_norm;
wifi_data = avg_weekday;

for i = 1:length(wifi_data)
    wifi_data{i} = table2array( wifi_data{i});
end

for i= 1:length(wifi_classify_data)
wifi_classify_data{i} = wifi_classify_data{i}';
end

miniBatchSize = 48;

YPred = classify(wifi_class_net,wifi_classify_data, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');

YPred = string(YPred);

% if any class is missing identify as unidentifiable 

YPred(ismissing(YPred)) = "Unidentifiable";

numClasses = length(unique(YPred));

classes = string(unique(YPred));

classes(ismissing(classes)) = "Unidentifiable";


for i = 1:length(area)
    building_name(i,1) = area{1,i}.Building(1);
    Floor(i,1) = area{1,i}.Floor(1);
end


classify_verify = table(YPred,building_name,Floor, wifi_classify_data,wifi_data);



   for n = 1:numClasses
     for j = 1:height(classify_verify)
         if classify_verify.YPred(j) == classes(n)
             type_classify{1,n}(j,:) = classify_verify(j,:);  
         end
     end   
 end
 
  for n = 1:numClasses
      type_classify{1,n} = type_classify{1,n}(~ismissing(type_classify{1,n}.YPred),:);
  end
  
  % plots all the meters per class in 3 subplots 

   for j = 1:numClasses
     figure(15)
     for f = 1:height(type_classify{1,j})
         subplot(2,3,j)
         plot(time,cell2mat(type_classify{1,j}.wifi_classify_data(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' type_classify{j}.YPred(1) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
   end
   
   % plots average profile for each class
   
   letters = string({'a','b','c','d','e','f','g'});
   
   for j = 1:numClasses
       avg_profile(:,j) = mean(cell2mat(type_classify{j}.wifi_classify_data));
       figure(55)
       subplot(1,3,j)
       plot(time,avg_profile(:,j))
       hold on 
       %legend([type{1,j}.building_names_train])
       title([ letters(j)])
       %sgtitle([Metertype '-' DataMonth])
   end
   


for n = 1:numClasses
    build_type_total(n) = trapz(cell2mat(type_classify{n}.wifi_data(1)));
    for i = 2:height(type_classify{n})
        build_type_total(n) = build_type_total(n) + trapz(cell2mat(type_classify{n}.wifi_data(i)));
    end
end



% Creates pie chart showing fraction of building types the building illustrates
figure()
pie(build_type_total)
legend([classes])
title('Pie Chart to Illustrate the Building Type Distribution')




