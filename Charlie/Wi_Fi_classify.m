%% Wi-Fi Cluster/Classify Train

% CODE TO IDENTIFY CLUSTERS AND TRAIN AND LSTM MODEL

%% Import the Data and Change Strings to Categories

clear all

wifidata_train = readtable('C:\Users\charl\AppData\Local\Temp\wifi_2020-02.csv');

wifidata_train.Building = categorical(wifidata_train.Building);
wifidata_train.Floor = categorical(wifidata_train.Floor);

wifidata_test = readtable('C:\Users\charl\AppData\Local\Temp\wifi_2019-05.csv');

wifidata_test.Building = categorical(wifidata_test.Building);
wifidata_test.Floor = categorical(wifidata_test.Floor);


%% Split and Plot the Data (based on 'name'/MeterID)


% finds the new number of meters in the data 
G = findgroups(wifidata_train.Building, wifidata_train.Floor);  
numberofareas = max(G);
G_test = findgroups(wifidata_test.Building, wifidata_test.Floor);  
numberofareas_test = max(G_test);

% creates a cell that contains the indidual columns of data for each meter
areas_train = splitapply( @(varargin) varargin, wifidata_train, G);
areas_test = splitapply( @(varargin) varargin, wifidata_test, G_test);

% calculates the number of columns in the data 
Width = width(wifidata_train);
Width_test = width(wifidata_test);

% creates a cell that contains all of the information for each cell for
% training (creates a training set)
for i = 1:numberofareas
    for j = 1:Width
        area_training{1,i}(:,j) = table(areas_train{i,j});
    end
end  

% repeats for testing

for i = 1:numberofareas_test
    for j = 1:Width_test
        area_testing{1,i}(:,j) = table(areas_test{i,j});
    end
end  

%%

% assigns the appropraiet variable names to all of the meter tables

for i = 1:numberofareas
    area_training{1, i}.Properties.VariableNames{1} = 'time';
    area_training{1, i}.Properties.VariableNames{2} = 'EventTime';
    area_training{1, i}.Properties.VariableNames{3} = 'AssociatedClientCount';
    area_training{1, i}.Properties.VariableNames{4} = 'AuthenticatedClientCount';
    area_training{1, i}.Properties.VariableNames{5} = 'Uni';
    area_training{1, i}.Properties.VariableNames{6} = 'Building';
    area_training{1, i}.Properties.VariableNames{7} = 'Floor';
   

end



% repeat for testing

for i = 1:numberofareas_test
    area_testing{1, i}.Properties.VariableNames{1} = 'time';
    area_testing{1, i}.Properties.VariableNames{2} = 'EventTime';
    area_testing{1, i}.Properties.VariableNames{3} = 'AssociatedClientCount';
    area_testing{1, i}.Properties.VariableNames{4} = 'AuthenticatedClientCount';
    area_testing{1, i}.Properties.VariableNames{5} = 'Uni';
    area_testing{1, i}.Properties.VariableNames{6} = 'Building';
    area_testing{1, i}.Properties.VariableNames{7} = 'Floor';
 
end





%% Average Daily Profile for each meter for this particular month

% fill out any missing parts to data

for i = 1:length(area_training)
TT_Train{1,i} = table2timetable(area_training{1,i});
TT_Train{1,i} = sortrows(TT_Train{1, i},'time','ascend');
TT_Train{1,i} = unique(TT_Train{1,i});
TT_Train{1,i} = rmmissing(TT_Train{1,i});
TT_Train{1,i} = retime(TT_Train{1,i},'regular', 'previous','TimeStep',minutes(5));
end

for i = 1:length(area_testing)
TT_Test{1,i} = table2timetable(area_testing{1,i});
TT_Test{1,i} = sortrows(TT_Test{1, i},'time','ascend');
TT_Test{1,i} = unique(TT_Test{1,i});
TT_Test{1,i} = rmmissing(TT_Test{1,i});
TT_Test{1,i} = retime(TT_Test{1,i},'regular', 'previous','TimeStep',minutes(5));
end

% converts the timetable back to a table
for i = 1:length(area_training)
area_train{1,i} = timetable2table(TT_Train{1,i});
end

for i = 1:length(area_testing)
area_test{1,i} = timetable2table(TT_Test{1,i});
end


% fills out missing data points, configures average daily profile for a
% weekday and for weekend that is normalised and smoothed out 

 for i = 1:length(area_training)
      DayNumber = weekday(area_train{1,i}.time); 
 timeofDay = timeofday(area_train{1,i}.time);
 WeekEnd = isweekend(area_train{1,i}.time);
 
 area_train{1,i}.Weekend = WeekEnd;
 area_train{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(area_train{1,i}.Weekend, area_train{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 area_train{1,i}.group = groups;
 l = height(area_train{1,i});
 
 % constructs a time variable for plotting purposes
 time1 = datetime(2018,1,1,0,0,0);
 time2 = datetime(2018,1,1,23,55,0);
 time = time1:minutes(5):time2;
 


 Weekday_train = groupsummary(area_train{1,i},{'group'},'mean','AssociatedClientCount','IncludeMissingGroups',false);
 Weekday_train.Properties.VariableNames{3} = 'Average_Reading';
 

 % creates average normalised and non normalised weekday and weekend
 % profiles
avg_weekday_train{i,1} = normalize(movavg(Weekday_train.Average_Reading(1:288),'simple',20),'range');
avg_weekday_train2{i,1} = movavg(Weekday_train.Average_Reading(1:288),'simple',20);

avg_weekend_train{i,1} = normalize(movavg(Weekday_train.Average_Reading(289:end),'simple',20),'range');
avg_weekend_train2{i,1} = movavg(Weekday_train.Average_Reading(289:end),'simple',20);


 end
 
 
% repeats for test

 for i = 1:length(area_test)
      DayNumber = weekday(area_test{1,i}.time); 
 timeofDay = timeofday(area_test{1,i}.time);
 WeekEnd = isweekend(area_test{1,i}.time);
 
 area_test{1,i}.Weekend = WeekEnd;
 area_test{1,i}.Timeofday = timeofDay;
 
 % finds groups based on the time of the day and what day of the week it is(for example, one group would be Tuesday at 13:00)
 groups = findgroups(area_test{1,i}.Weekend, area_test{1,i}.Timeofday);
 
 % adds the groups as a variable to each table in the cell
 area_test{1,i}.group = groups;
 l = height(area_test{1,i});
 

 Weekday_test = groupsummary(area_test{1,i},{'group'},'mean','AssociatedClientCount','IncludeMissingGroups',false);
 Weekday_test.Properties.VariableNames{3} = 'Average_Reading';

% creates normalised and non normalised avg weekday and weekend profiles 
avg_weekday_test{i,1} = normalize(movavg(Weekday_test.Average_Reading(1:288),'simple',20),'range');
avg_weekday_test2{i,1} = movavg(Weekday_test.Average_Reading(1:288),'simple',20);

avg_weekend_test{i,1} = normalize(movavg(Weekday_test.Average_Reading(289:end),'simple',20),'range');
avg_weekend_test2{i,1} = movavg(Weekday_test.Average_Reading(289:end),'simple',20);


 end
%% Clustering prep

clear building_names_train
clear Floor_train
clear units
clear Heirarchical
clear type
clear cluster_energy_weekday_train
clear cluster_verify2

% creates a pre-defined sized array for training and testing data to
% convert from table format

cluster_wifi_weekday_train = zeros(length(avg_weekday_train),288);
cluster_wifi_weekday_test = zeros(length(avg_weekday_test),288);


for i = 1:length(area_train)
    building_names_train(i,1) = string(area_train{i}.Building(2));
    Floor_train(i,1) = area_train{i}.Floor(2);
end

% UNCOMMENT if you want to verify and observe the average daily profiles
% for i = 1:length(avg_weekday_train)
%     figure(i)
% plot(time', avg_weekday_train{i})
% title([building_names_train(i) '-' meter_description_train(i)])
% end


for i = 1:length(area_test)
    building_names_test(i,1) = string(area_test{i}.Building(1));
    Floor_test(i,1) = area_test{i}.Floor(1);
    
end

% Clustering train

% uncommet if not using dtw distance 
distance_method = ["euclidean" "squaredeuclidean" "seuclidean" "mahalanobis" "cityblock" "minkowski" "chebychev" "cosine" "correlation" "hamming" "jaccard" "spearman"];
linkage_method = ["average" "centroid" "complete" "median" "single" "ward" "weighted"];


for i = 1:length(area_training)
    x = length(avg_weekday_train{i});  %should be 288
    cluster_wifi_weekday_train(i,1:x) = avg_weekend_train{i};
end

% change to change distance and linkage methods and max clusters
i = 1;
j = 6;
numclusters = 4;

% cluster process
Y = pdist(cluster_wifi_weekday_train,distance_method(i));
Z = linkage(Y, linkage_method(j));
figure(i*10)
dendrogram(Z)
title([distance_method(i) '-' linkage_method(j)])
I = inconsistent(Z);
Heirarchical = cluster(Z,'maxclust',numclusters);


numberofmeters = length(area_train);

building_names_train = building_names_train';
meter_description_train= meter_description_train';
units_train = units_train';

% creates a table to understand how the buildings have been clustered
cluster_verify2_train = table(Heirarchical, building_names_train,Floor_train, avg_weekday_train); %string(building_types_train));


% seperates the clusters and plots the buildings in the cluster specified 
 for n = 1:max(Heirarchical)
     for j = 1:height(cluster_verify2_train)
         if cluster_verify2_train.Heirarchical(j) == n
             type{1,n}(j,:) = cluster_verify2_train(j,:);  
         end
     end   
 end

 
 
 
  for n = 1:max(Heirarchical)
      type{1,n} = type{1,n}(type{1,n}.Heirarchical ~= 0,:);
  end
  

 
 
 for j = 1:numclusters
     figure(4)
     for f = 1:height(type{1,j})
         subplot(2,round(numclusters/2),j)
         plot(time,cell2mat(type{1,j}.avg_weekday_train(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' num2str(j) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
 end
 
 % for plotting individual group
%  for j = 8
%      figure(13)
%      for f = 1:height(type{1,j})
%          plot(time,cell2mat(type{1,j}.avg_weekday_train(f)))
%          hold on
%      end
%      legend([type{1,j}.building_names_train])
%      title(['type' '-' num2str(j) '-' 'building'])
%      %sgtitle([Metertype '-' DataMonth])
%  end

%%
Heirarchical_orig = Heirarchical;
%Heirarchical = Heirarchical_orig;

% assign classes to clusters 

 for i = 1:length(Heirarchical)
     if Heirarchical(i) == 6
         Building_Type(i,1) = "Working Day";
     elseif Heirarchical(i) == 4 
         Building_Type(i,1) = "Residential";
     elseif Heirarchical(i) == 1
         Building_Type(i,1) = "Residential";
     elseif Heirarchical(i) == 2
         Building_Type(i,1) = "Residential";
     elseif Heirarchical(i) == 5
         Building_Type(i,1) = "Recreational";
     elseif Heirarchical(i) == 3
         Building_Type(i,1) = "Zero";
     else 
         Building_Type(i,1) = "Other";
     
     end
 end



 %% LSTM 
% train LSTM model
 
% ensure cells are arranged in correct way

for i= 1:length(avg_weekday_train)
avg_weekday_train{i} = avg_weekday_train{i}';
end


for i= 1:length(avg_weekday_test)
avg_weekday_test{i} = avg_weekday_test{i}';
end

inputSize = 1;
numHiddenUnits = 100;
numClasses = 4;

layers = [ ...
    sequenceInputLayer(inputSize)
    bilstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];


% 'ValidationData',{avg_weekday_test,building_types_test}, ...

miniBatchSize = 48;
options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'MaxEpochs',100, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...
    'Plots','training-progress');

Building_Type = categorical(Building_Type);

wifi_class_net = trainNetwork(avg_weekday_train,Building_Type,layers,options);

save('wifi_class_net.mat', 'wifi_class_net');


YPred = classify(wifi_class_net,avg_weekday_test, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');


YPred = double(YPred);


% Table to compare classification
classify_verify = table(YPred,building_names_test,Floor_test, avg_weekday_test, avg_weekday_test2);


 for n = 1:numClasses
     for j = 1:height(classify_verify)
         if classify_verify.YPred(j) == n
             type_classify{1,n}(j,:) = classify_verify(j,:);  
         end
     end   
 end
 

 %%
 % plot each class

 for j = 1:numClasses
     figure(13)
     for f = 1:height(type_classify{1,j})
         subplot(round(numClasses/2),2,j)
         plot(time,cell2mat(type_classify{1,j}.avg_weekday_test(f)))
         hold on
     end
     %legend([type{1,j}.building_names_train])
     title(['type' '-' num2str(j) '-' 'building'])
     %sgtitle([Metertype '-' DataMonth])
 end




 %% Dynamic Time Warping (DTW) Function

 function dist = dtwf(x,y)
% n = numel(x);
m2 = size(y,1);
dist = zeros(m2,1);
for i=1:m2
    dist(i) = dtw(x,y(i,:));
end
end