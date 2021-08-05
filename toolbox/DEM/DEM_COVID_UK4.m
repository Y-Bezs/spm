function DCM = DEM_COVID_UK4
% FORMAT DCM = DEM_COVID_UK4
%
% Demonstration of COVID-19 modelling using variational Laplace (4 groups)
%__________________________________________________________________________
%
% This routine illustrates Bayesian model comparison using a line search
% over periods of imunity and pooling over countries. In brief,32 countries
% are inverted and 16 with the most informative posterior over the period
% of immunity are retained for Bayesian parameter averaging. The Christian
% predictive densities are then provided in various formats for the average
% country and (16) individual countries.
%__________________________________________________________________________
% Copyright (C) 2020 Wellcome Centre for Human Neuroimaging

% Karl Friston
% $Id: DEM_COVID_UK.m 8112 2021-06-16 20:06:47Z karl $

% set up and preliminaries
%==========================================================================
% https://www.ons.gov.uk/peoplepopulationandcommunity/healthandsocialcare/conditionsanddiseases/datasets/coronaviruscovid19infectionsurveydata
% https://www.ndm.ox.ac.uk/covid-19/covid-19-infection-survey/results
% https://coronavirus.data.gov.uk/
% https://covid.joinzoe.com/data#levels-over-time
% https://www.gov.uk/guidance/the-r-number-in-the-uk#history
% https://www.gov.uk/government/statistics/transport-use-during-the-coronavirus-covid-19-pandemic
% https://www.google.com/covid19/mobility/

% F = -2.5929e+04

% set up and get data
%==========================================================================
clear all
close all
clc
spm_figure('GetWin','SI'); clf;
cd('C:\Users\karl\Dropbox\Coronavirus\Dashboard')

% Files to be updated by hand
%--------------------------------------------------------------------------
% url = 'https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/healthandsocialcare/conditionsanddiseases/datasets/coronaviruscovid19antibodydatafortheuk/2021/20210414covid19infectionsurveydatasets.xlsx'
% tab = webread(url);
% url = 'https://www.ons.gov.uk/generator?uri=/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/bulletins/deathsregisteredweeklyinenglandandwalesprovisional/weekending19february2021/8714ef2a&format=csv';
% writetable(webread(url,options),'place.csv');


%% web options
%--------------------------------------------------------------------------
options = weboptions('ContentType','table');
options.Timeout = 20;

% download data and write to CSV files
%--------------------------------------------------------------------------
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=newCasesBySpecimenDate&format=csv';
writetable(webread(url,options),'cases.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=newDeaths28DaysByDeathDate&format=csv';
writetable(webread(url,options),'deaths.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=covidOccupiedMVBeds&format=csv';
writetable(webread(url,options),'critical.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=newTestsByPublishDate&format=csv';
writetable(webread(url,options),'tests.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=newAdmissions&format=csv';
writetable(webread(url,options),'admissions.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=hospitalCases&format=csv';
writetable(webread(url,options),'occupancy.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=overview&metric=newOnsDeathsByRegistrationDate&format=csv';
writetable(webread(url,options),'certified.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=uniqueCasePositivityBySpecimenDateRollingSum&format=csv';
writetable(webread(url,options),'positivity.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=newLFDTests&format=csv';
writetable(webread(url,options),'lateralft.csv');
url = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=cumAntibodyTestsByPublishDate&format=csv';
writetable(webread(url,options),'antibody.csv');

% get death by age (England)
%--------------------------------------------------------------------------
url   = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=newDeaths28DaysByDeathDateAgeDemographics&format=csv';
tab   = webread(url,options);
vnames = tab.Properties.VariableNames;
aa     = find(ismember(vnames,'age'));
ad     = find(ismember(vnames,'date'));
an     = find(ismember(vnames,'deaths'));
age   = unique(tab(:,aa));
for r = 1:numel(age)
    j = find(ismember(tab(:,aa),age(r,1)));
    agedeaths(:,1)     = tab(j,ad);
    agedeaths(:,r + 1) = tab(j,an);
end
agedeaths = renamevars(agedeaths,(1:numel(age)) + 1,table2array(age));
writetable(agedeaths,'agedeaths.csv')

% get cases by age (England)
%----------------------------------------------------------------------
url   = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=newCasesBySpecimenDateAgeDemographics&format=csv';
tab   = webread(url,options);
vnames = tab.Properties.VariableNames;
aa     = find(ismember(vnames,'age'));
ad     = find(ismember(vnames,'date'));
an     = find(ismember(vnames,'cases'));
age   = unique(tab(:,aa));
for r = 1:numel(age)
    j = find(ismember(tab(:,aa),age(r,1)));
    agecases(:,1)     = tab(j,ad);
    agecases(:,r + 1) = tab(j,an);
end
agecases = renamevars(agecases,(1:numel(age)) + 1,table2array(age));
writetable(agecases,'agecases.csv')

% get vaccination by age (England)
%----------------------------------------------------------------------
url   = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=vaccinationsAgeDemographics&format=csv';
tab   = webread(url,options);
vnames = tab.Properties.VariableNames;
aa     = find(ismember(vnames,'age'));
ad     = find(ismember(vnames,'date'));
an     = find(ismember(vnames,'cumVaccinationFirstDoseUptakeByVaccinationDatePercentage'));
age   = unique(tab(:,aa));
for r = 1:numel(age)
    j = find(ismember(tab(:,aa),age(r,1)));
    agevaccine(:,1)     = tab(j,ad);
    agevaccine(:,r + 1) = tab(j,an);
end
agevaccine = renamevars(agevaccine,(1:numel(age)) + 1,table2array(age));
writetable(agevaccine,'agevaccine.csv')

% get (cumulative) admissions by age (England)
%----------------------------------------------------------------------
url   = 'https://api.coronavirus.data.gov.uk/v2/data?areaType=nation&areaCode=E92000001&metric=cumAdmissionsByAge&format=csv';
tab   = webread(url,options);
vnames = tab.Properties.VariableNames;
aa     = find(ismember(vnames,'age'));
ad     = find(ismember(vnames,'date'));
an     = find(ismember(vnames,'value'));
age   = unique(tab(:,aa));
for r = 1:numel(age)
    j = find(ismember(tab(:,aa),age(r,1)));
    cumAdmiss(:,1)     = tab(j,ad);
    cumAdmiss(:,r + 1) = tab(j,an);
end
cumAdmiss = renamevars(cumAdmiss,(1:numel(age)) + 1,table2array(age));
writetable(cumAdmiss,'cumAdmiss.csv')


% mobility and transport
%--------------------------------------------------------------------------
url = 'https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/947572/COVID-19-transport-use-statistics.ods.ods';
writetable(webread(url,options),'transport.csv');

ndy = 321;
url = 'https://www.gstatic.com/covid19/mobility/2020_GB_Region_Mobility_Report.csv';
tab = webread(url);
writetable(tab(1:ndy,9:12),'mobility20.csv');

ndy = datenum(date) - datenum(datestr('01/01/2021','dd/mm/yyyy'));
url = 'https://www.gstatic.com/covid19/mobility/2021_GB_Region_Mobility_Report.csv';
tab = webread(url);
writetable(tab(1:ndy,9:12),'mobility21.csv');


% Country Code	K02000001	K03000001	K04000001	E92000001	W92000004	S92000003	N92000002	
% All Persons	67,081,234	65,185,724	59,719,724	56,550,138	3,169,586	5,466,000	1,895,510	
%--------------------------------------------------------------------------
% population sizes (millions) in five year bins
%--------------------------------------------------------------------------
% {'00_04','05_09','10_14','15_19','20_24','25_29','30_34','35_39',...
%  '40_44','45_49','50_54','55_59','60_64','65_69','70_74','75_79', ...
%  '80_84','85_89','90+'};
%--------------------------------------------------------------------------
N  = [3.86, 4.15, 3.95, 3.66, 4.15, 4.51, 4.50, 4.40, 4.02, 4.4, 4.66, ...
      4.41, 3.76, 3.37, 3.32, 2.33, 1.72, 1.04, 0.61];
  
N  = 67.08*N/sum(N);

% ONS age bands
%--------------------------------------------------------------------------
ons{1} = [sum(N(4:5))  sum(N(6:7))];                   % 15_34
ons{2} = [sum(N(8:10)) sum(N(11:12)) N(13) N(14)];     % 35_69
ons{3} = [N(15) N(16)  sum(N(17:end))];                % >70
for i = 1:numel(ons)
    ons{i} = ons{i}'/sum(ons{i});
end

% PHE age bands
%--------------------------------------------------------------------------
phe{1} = [sum(N(1:2)) N(3)];                           % <15
phe{2} = [sum(N(4:5)) sum(N(6:7)) ];                   % 15_34
phe{3} = [sum(N(8:10)) sum(N(11:14))];                 % 35_69
phe{4} = [sum(N(15:end))];                             % >70
for i = 1:numel(phe)
    phe{i} = phe{i}'/sum(phe{i});
end

% Vaccine ONS age bands
%--------------------------------------------------------------------------
iv2     = 1:3;                                          % 15-35
iv3     = 4:10;                                         % 35-70
iv4     = 11:15;                                        % >70

vons{1} = N(5:7);                                       % 15_34
vons{2} = N(8:14);                                      % 35_69
vons{3} = N(15:19);                                     % >70
for i = 1:numel(vons)
    vons{i} = vons{i}'/sum(vons{i});
end

% cumulative admissions ONS age bands: 0_to_5 18_to_64 65_to_84 6_to_17 85+
%--------------------------------------------------------------------------
cum     = [1 0     0     6/10 0;
           0 15/45 0     4/10 0;
           0 30/45 4/20  0    0;
           0 0     16/20 0    1]';  

% DCM age bands <15 15_34 35_69 >70
%--------------------------------------------------------------------------
N   = [sum(N(1:3)) sum(N(4:7)) sum(N(8:14)) sum(N(15:end))];
nN  = numel(N);


%% import data
%--------------------------------------------------------------------------
cases      = importdata('cases.csv');
deaths     = importdata('deaths.csv');
ccu        = importdata('critical.csv');
tests      = importdata('tests.csv');
certified  = importdata('certified.csv');
admissions = importdata('admissions.csv');
occupancy  = importdata('occupancy.csv');
positivity = importdata('positivity.csv');
lateralft  = importdata('lateralft.csv');
transport  = importdata('transport.csv');
mobility20 = importdata('mobility20.csv');
mobility21 = importdata('mobility21.csv');
agevaccine = importdata('agevaccine.csv');
agedeaths  = importdata('agedeaths.csv');
agecases   = importdata('agecases.csv');
cumAdmiss  = importdata('cumAdmiss.csv');
antibody   = importdata('antibody.csv');


serology   = importdata('serology.csv');
place      = importdata('place.csv');
survey     = importdata('survey.csv');
surveyage  = importdata('surveyage.csv');
symptoms   = importdata('symptoms.csv');
ratio      = importdata('ratio.csv');

d          = find(ismember(cases.textdata(1,1:end),'date'));

% create data structure
%--------------------------------------------------------------------------
Y(1).type = 'Positive virus tests (ONS)'; % daily positive cases
Y(1).unit = 'number/day';
Y(1).U    = 2;
Y(1).date = datenum(cases.textdata(2:end,d),'yyyy-mm-dd');
Y(1).Y    = cases.data(:,1);
Y(1).h    = 0;
Y(1).lag  = 1;
Y(1).age  = 0;
Y(1).hold = 0;

Y(2).type = 'Virus tests (ONS)'; % newVirusTests (England)
Y(2).unit = 'number/day';
Y(2).U    = 6;
Y(2).date = datenum(tests.textdata(2:end,d),'yyyy-mm-dd');
Y(2).Y    = tests.data(:,1)*6708/5655;
Y(2).h    = 0;
Y(2).lag  = 0;
Y(2).age  = 0;
Y(2).hold = 1;

Y(3).type = 'Virus/LFD tests (GOV)'; % newLFDTests (England)
Y(3).unit = 'number/day';
Y(3).U    = 24;
Y(3).date = datenum(lateralft.textdata(2:end,d),'yyyy-mm-dd');
Y(3).Y    = lateralft.data(:,1)*6708/5655;
Y(3).h    = 0;
Y(3).lag  = 0;
Y(3).age  = 0;
Y(3).hold = 0;

Y(4).type = 'Prevalence (ONS)'; % number of people infected (England)
Y(4).unit = 'percent';
Y(4).U    = 11;
Y(4).date = datenum(survey.textdata(2:end,1),'dd/mm/yyyy') - 7;
Y(4).Y    = survey.data(:,1);
Y(4).h    = 0;
Y(4).lag  = 1;
Y(4).age  = 0;
Y(4).hold = 0;

Y(5).type = 'Daily deaths (ONS: 28-days)'; % covid-related deaths (28 days)
Y(5).unit = 'number/day';
Y(5).U    = 1;
Y(5).date = datenum(deaths.textdata(2:end,d),'yyyy-mm-dd');
Y(5).Y    = deaths.data(:,1);
Y(5).h    = 2;
Y(5).lag  = 1;
Y(5).age  = 0;
Y(5).hold = 0;

Y(6).type = 'Certified deaths (ONS)'; % weekly covid related deaths
Y(6).unit = 'number';
Y(6).U    = 15;
Y(6).date = datenum(certified.textdata(2:end,d),'yyyy-mm-dd') - 10;
Y(6).Y    = certified.data(:,1)/7;
Y(6).h    = 2;
Y(6).lag  = 0;
Y(6).age  = 0;
Y(6).hold = 0;

Y(7).type = 'Admissions (ONS)'; % admissions to hospital
Y(7).unit = 'number';
Y(7).U    = 16;
Y(7).date = datenum(admissions.textdata(2:end,d),'yyyy-mm-dd');
Y(7).Y    = admissions.data(:,1);
Y(7).h    = 2;
Y(7).lag  = 0;
Y(7).age  = 0;
Y(7).hold = 0;

Y(8).type = 'Occupancy (ONS)'; % Hospital cases
Y(8).unit = 'number';
Y(8).U    = 27;
Y(8).date = datenum(occupancy.textdata(2:end,d),'yyyy-mm-dd');
Y(8).Y    = occupancy.data(:,1);
Y(8).h    = 0;
Y(8).lag  = 1;
Y(8).age  = 0;
Y(8).hold = 0;

Y(9).type = 'Ventilated patients (ONS)'; % CCU occupancy (mechanical)
Y(9).unit = 'number';
Y(9).U    = 3;
Y(9).date = datenum(ccu.textdata(2:end,d),'yyyy-mm-dd');
Y(9).Y    = ccu.data(:,1);
Y(9).h    = 0;
Y(9).lag  = 0;
Y(9).age  = 0;
Y(9).hold = 0;

Y(10).type = 'PCR positivity (GOV)'; % positivity (England)
Y(10).unit = 'percent';
Y(10).U    = 23;
Y(10).date = datenum(positivity.textdata(2:end,d),'yyyy-mm-dd');
Y(10).Y    = positivity.data(:,1);
Y(10).h    = 0;
Y(10).lag  = 1;
Y(10).age  = 0;
Y(10).hold = 0;

Y(11).type = 'Symptoms (KCL)'; % number of people reporting symptoms (UK)
Y(11).unit = 'number';
Y(11).U    = 12;
Y(11).date = datenum(symptoms.textdata(2:end,1),'dd/mm/yyyy');
Y(11).Y    = symptoms.data(:,1);
Y(11).h    = 0;
Y(11).lag  = 1;
Y(11).age  = 0;
Y(11).hold = 0;

Y(12).type = 'R-ratio (WHO/GOV)'; % the production ratio
Y(12).unit = 'ratio';
Y(12).U    = 4;
Y(12).date = [datenum(ratio.textdata(2:end,1),'dd/mm/yyyy') - 16; ...
    datenum(ratio.textdata(2:end,1),'dd/mm/yyyy') - 15];
Y(12).Y    = [ratio.data(:,1); ratio.data(:,2)];
Y(12).h    = 2;
Y(12).lag  = 1;
Y(12).age  = 0;
Y(12).hold = 0;

Y(13).type = 'Transport (GOV)'; % cars (percent)
Y(13).unit = 'percent';
Y(13).U    = 13;
Y(13).Y    = transport.data(:,1)*100;
Y(13).date = datenum(transport.textdata(1 + (1:numel(Y(13).Y)),1),'dd-mm-yyyy');
Y(13).h    = 0;
Y(13).lag  = 0;
Y(13).age  = 0;
Y(13).hold = 1;

Y(14).type = 'Mobility (GOV/Google)'; % retail and recreation (percent)
Y(14).unit = 'percent';
Y(14).U    = 14;
Y(14).date = [datenum(mobility20.textdata(2:end,1),'yyyy-mm-dd') ;
              datenum(mobility21.textdata(2:end,1),'yyyy-mm-dd')];
Y(14).Y    = [mobility20.data(:,1); mobility21.data(:,1)] + 100;
Y(14).h    = 0;
Y(14).lag  = 0;
Y(14).age  = 0;
Y(14).hold = 0;

% scaling for data from England and Wales 
%--------------------------------------------------------------------------
EngWale    = sum(sum(place.data(1:end - 8,1:4),2));
UK         = sum(certified.data(:,1));
EngWaleUK  = UK/EngWale;

Y(15).type = 'Hospital deaths (PHE)'; % hospital deaths
Y(15).unit = 'number';
Y(15).U    = 17;
Y(15).date = datenum(place.textdata(2:end - 8,1),'dd/mm/yyyy');
Y(15).Y    = place.data(1:end - 8,4)*EngWaleUK;
Y(15).h    = 0;
Y(15).lag  = 1;
Y(15).age  = 0;
Y(15).hold = 1;

Y(16).type = 'Hospital/Other deaths (PHE)'; % nonhospital deaths
Y(16).unit = 'number';
Y(16).U    = 18;
Y(16).date = datenum(place.textdata(2:end - 8,1),'dd/mm/yyyy');
Y(16).Y    = sum(place.data(1:end - 8,1:3),2)*EngWaleUK;
Y(16).h    = 0;
Y(16).lag  = 1;
Y(16).age  = 4;                             % in older cohort
Y(16).hold = 0;

% age-specific data
%--------------------------------------------------------------------------
j          = find(~ismember(serology.textdata(1,2:end),''));
Y(17).type = 'Seropositive 15-35 (PHE)'; % percent antibody positive (England)
Y(17).unit = 'percent';
Y(17).U    = 5;
Y(17).date = datenum(serology.textdata(2:end,1),'dd/mm/yyyy');
Y(17).Y    = serology.data(:,j(1:2))*ons{1};
Y(17).h    = 2;
Y(17).lag  = 0;
Y(17).age  = 2;
Y(17).hold = 1;

Y(18).type = 'Seropositive 35-70 (PHE)'; % percent antibody positive (England)
Y(18).unit = 'percent';
Y(18).U    = 5;
Y(18).date = datenum(serology.textdata(2:end,1),'dd/mm/yyyy');
Y(18).Y    = serology.data(:,j(3:6))*ons{2};
Y(18).h    = 2;
Y(18).lag  = 0;
Y(18).age  = 3;
Y(18).hold = 1;

Y(19).type = 'Seropositive 15-35-70- (PHE)'; % percent antibody positive (England)
Y(19).unit = 'percent';
Y(19).U    = 5;
Y(19).date = datenum(serology.textdata(2:end,1),'dd/mm/yyyy');
Y(19).Y    = serology.data(:,j(7:9))*ons{3};
Y(19).h    = 2;
Y(19).lag  = 0;
Y(19).age  = 4;
Y(19).hold = 0;


Y(20).type = 'First dose 15-35 (PHE)'; % percent vaccinated (England)
Y(20).unit = 'percent';
Y(20).U    = 22;
Y(20).date = datenum(agevaccine.textdata(2:end,1),'yyyy-mm-dd');
Y(20).Y    = agevaccine.data(:,iv2)*vons{1};
Y(20).h    = 2;
Y(20).lag  = 0;
Y(20).age  = 2;
Y(20).hold = 1;

Y(21).type = 'First dose 35-70 (PHE)'; % percent vaccinated (England)
Y(21).unit = 'percent';
Y(21).U    = 22;
Y(21).date = datenum(agevaccine.textdata(2:end,1),'yyyy-mm-dd');
Y(21).Y    = agevaccine.data(:,iv3)*vons{2};
Y(21).h    = 2;
Y(21).lag  = 0;
Y(21).age  = 3;
Y(21).hold = 1;

Y(22).type = 'First dose 15-35-70- (PHE)'; % percent vaccinated (England)
Y(22).unit = 'percent';
Y(22).U    = 22;
Y(22).date = datenum(agevaccine.textdata(2:end,1),'yyyy-mm-dd');
Y(22).Y    = agevaccine.data(:,iv4)*vons{3};
Y(22).h    = 2;
Y(22).lag  = 0;
Y(22).age  = 4;
Y(22).hold = 0;

% scaling for data from England
%--------------------------------------------------------------------------
ig1        = [1 3 4];                                % <15
ig2        = [5 6 7 8];                              % 15-35
ig3        = [9 10 11 12 13 15 16];                  % 35-70
ig4        = [17 18 19 20 21];                       % >70
ig         = [ig1 ig2 ig3 ig4];
England    = sum(sum(agedeaths.data(:,ig),2));
UK         = sum(deaths.data(4:end,1));
EnglandUK  = UK/England;


Y(23).type = 'Deaths <15(PHE)'; % deaths (English hospitals)
Y(23).unit = 'number';
Y(23).U    = 1;
Y(23).date = datenum(agedeaths.textdata(2:end,1),'yyyy-mm-dd');
Y(23).Y    = sum(agedeaths.data(:,ig1),2)*EnglandUK;
Y(23).h    = 2;
Y(23).lag  = 0;
Y(23).age  = 1;
Y(23).hold = 1;

Y(24).type = 'Deaths 15-35 (PHE)'; % deaths (English hospitals)
Y(24).unit = 'number';
Y(24).U    = 1;
Y(24).date = datenum(agedeaths.textdata(2:end,1),'yyyy-mm-dd');
Y(24).Y    = sum(agedeaths.data(:,ig2),2)*EnglandUK;
Y(24).h    = 2;
Y(24).lag  = 0;
Y(24).age  = 2;
Y(24).hold = 1;

Y(25).type = 'Deaths 35-70 (PHE)'; % deaths (English hospitals)
Y(25).unit = 'number';
Y(25).U    = 1;
Y(25).date = datenum(agedeaths.textdata(2:end,1),'yyyy-mm-dd');
Y(25).Y    = sum(agedeaths.data(:,ig3),2)*EnglandUK;
Y(25).h    = 2;
Y(25).lag  = 0;
Y(25).age  = 3;
Y(25).hold = 1;

Y(26).type = 'Deaths -15-35-70- (PHE)'; % deaths (English hospitals)
Y(26).unit = 'number';
Y(26).U    = 1;
Y(26).date = datenum(agedeaths.textdata(2:end,1),'yyyy-mm-dd');
Y(26).Y    = sum(agedeaths.data(:,ig4),2)*EnglandUK;
Y(26).h    = 2;
Y(26).lag  = 0;
Y(26).age  = 4;
Y(26).hold = 0;

England    = sum(sum(agecases.data(:,ig),2));
UK         = sum(cases.data(4:end,1));
EnglandUK  = UK/England;

Y(27).type = 'New cases <15 (PHE)';  % New notifications (England)
Y(27).unit = 'number';
Y(27).U    = 2;
Y(27).date = datenum(agecases.textdata(2:end,1),'yyyy-mm-dd');
Y(27).Y    = sum(agecases.data(:,ig1),2)*EnglandUK;
Y(27).h    = 2;
Y(27).lag  = 1;
Y(27).age  = 1;
Y(27).hold = 1;

Y(28).type = 'New cases 15-35 (PHE)'; % New notifications  (England)
Y(28).unit = 'number';
Y(28).U    = 2;
Y(28).date = datenum(agecases.textdata(2:end,1),'yyyy-mm-dd');
Y(28).Y    = sum(agecases.data(:,ig2),2)*EnglandUK;
Y(28).h    = 2;
Y(28).lag  = 1;
Y(28).age  = 2;
Y(28).hold = 1;

Y(29).type = 'New cases 35-70 (PHE)'; % New notifications  (England)
Y(29).unit = 'number';
Y(29).U    = 2;
Y(29).date = datenum(agecases.textdata(2:end,1),'yyyy-mm-dd');
Y(29).Y    = sum(agecases.data(:,ig3),2)*EnglandUK;
Y(29).h    = 2;
Y(29).lag  = 1;
Y(29).age  = 3;
Y(29).hold = 1;

Y(30).type = 'New cases -15-35-70- (PHE)'; % New notifications  (England)
Y(30).unit = 'number';
Y(30).U    = 2;
Y(30).date = datenum(agecases.textdata(2:end,1),'yyyy-mm-dd');
Y(30).Y    = sum(agecases.data(:,ig4),2)*EnglandUK;
Y(30).h    = 2;
Y(30).lag  = 1;
Y(30).age  = 4;
Y(30).hold = 0;


j          = find(~ismember(surveyage.textdata(1,2:end),''));
Y(31).type = 'Prevalence <15 (PHE)';  % Estimated positivity (England)
Y(31).unit = 'percent';
Y(31).U    = 11;
Y(31).date = datenum(surveyage.textdata(2:end,1),'dd/mm/yyyy');
Y(31).Y    = surveyage.data(:,j(1:2))*phe{1};
Y(31).h    = 0;
Y(31).lag  = 0;
Y(31).age  = 1;
Y(31).hold = 1;

Y(32).type = 'Prevalence 25-65 (PHE)'; % Estimated positivity (England)
Y(32).unit = 'percent';
Y(32).U    = 11;
Y(32).date = datenum(surveyage.textdata(2:end,1),'dd/mm/yyyy');
Y(32).Y    = surveyage.data(:,j(3:4))*phe{2};
Y(32).h    = 0;
Y(32).lag  = 0;
Y(32).age  = 2;
Y(32).hold = 1;

Y(33).type = 'Prevalence 35-70 (PHE)'; % Estimated positivity (England)
Y(33).unit = 'percent';
Y(33).U    = 11;
Y(33).date = datenum(surveyage.textdata(2:end,1),'dd/mm/yyyy');
Y(33).Y    = surveyage.data(:,j(5:6))*phe{3};
Y(33).h    = 0;
Y(33).lag  = 0;
Y(33).age  = 3;
Y(33).hold = 1;

Y(34).type = 'Prevalence -15-35-70- (PHE)'; % Estimated positivity (England)
Y(34).unit = 'percent';
Y(34).U    = 11;
Y(34).date = datenum(surveyage.textdata(2:end,1),'dd/mm/yyyy');
Y(34).Y    = surveyage.data(:,j(7))*phe{4};
Y(34).h    = 0;
Y(34).lag  = 0;
Y(34).age  = 4;
Y(34).hold = 0;

England    = sum(max(cumAdmiss.data));
UK         = sum(admissions.data);
EnglandUK  = UK/England;

Y(35).type = 'Cumulative admissions <15 (ONS)';  % Cumulative admissions (England)
Y(35).unit = 'number';
Y(35).U    = 30;
Y(35).date = datenum(cumAdmiss.textdata(2:end,1),'yyyy-mm-dd');
Y(35).Y    = cumAdmiss.data*cum(:,1)*EnglandUK;
Y(35).h    = 0;
Y(35).lag  = 0;
Y(35).age  = 1;
Y(35).hold = 1;

Y(36).type = 'Cumulative admissions 15-35 (ONS)'; % Cumulative admissions (England)
Y(36).unit = 'number';
Y(36).U    = 30;
Y(36).date = datenum(cumAdmiss.textdata(2:end,1),'yyyy-mm-dd');
Y(36).Y    = cumAdmiss.data*cum(:,2)*EnglandUK;
Y(36).h    = 0;
Y(36).lag  = 0;
Y(36).age  = 2;
Y(36).hold = 1;

Y(37).type = 'Cumulative admissions 35-70 (ONS)'; % Cumulative admissions (England)
Y(37).unit = 'number';
Y(37).U    = 30;
Y(37).date = datenum(cumAdmiss.textdata(2:end,1),'yyyy-mm-dd');
Y(37).Y    = cumAdmiss.data*cum(:,3)*EnglandUK;
Y(37).h    = 0;
Y(37).lag  = 0;
Y(37).age  = 3;
Y(37).hold = 1;

Y(38).type = 'Cumulative admissions -15-35-70- (ONS)'; % Cumulative admissions (England)
Y(38).unit = 'number';
Y(38).U    = 30;
Y(38).date = datenum(cumAdmiss.textdata(2:end,1),'yyyy-mm-dd');
Y(38).Y    = cumAdmiss.data*cum(:,4)*EnglandUK;
Y(38).h    = 0;
Y(38).lag  = 0;
Y(38).age  = 4;
Y(38).hold = 0;


% remove NANs, smooth and sort by date
%==========================================================================
M.date  = '01-02-2020';
[Y,S]   = spm_COVID_Y(Y,M.date,16);


% get and set priors
%==========================================================================
[pE,pC] = spm_SARS_priors(nN);
pE.N    = log(N(:));
pC.N    = spm_zeros(pE.N);

% age-specific
%--------------------------------------------------------------------------
pE.mo   = zeros(nN,2);         % coefficients for mobility
pC.mo   = ones(nN,2)/8;        % prior variance
pE.wo   = zeros(nN,2);         % coefficients for retail
pC.wo   = ones(nN,2)/8;        % prior variance

% augment priors with fluctuations
%--------------------------------------------------------------------------
i       = floor((datenum(date) - datenum(M.date))/32);
j       = floor((datenum(date) - datenum(M.date))/48);
k       = floor((datenum(date) - datenum(M.date))/64);
pE.tra  = zeros(1,k);          % increases in transmission strength
pC.tra  = ones(1,k)/8;         % prior variance

pE.pcr  = zeros(1,j);          % testing
pC.pcr  = ones(1,j)/8;         % prior variance

pE.mob  = zeros(1,i);          % mobility
pC.mob  = ones(1,i)/8;         % prior variance

% reporting lags
%--------------------------------------------------------------------------
lag([Y.U]) = [Y.lag];
pE.lag  = spm_zeros(lag);      % reporting delays
pC.lag  = lag; 

% data structure with vectorised data and covariance components
%--------------------------------------------------------------------------
xY.y    = spm_vec(Y.Y);
xY.Q    = spm_Ce([Y.n]);
hE      = spm_vec(Y.h);

% model specification
%==========================================================================
M.Nmax = 16;                   % maximum number of iterations
M.G    = @spm_SARS_gen;        % generative function
M.FS   = @(Y)real(sqrt(Y));    % feature selection  (link function)
M.pE   = pE;                   % prior expectations (parameters)
M.pC   = pC;                   % prior covariances  (parameters)
M.hE   = hE;                   % prior expectation  (log-precision)
M.hC   = 1/512;                % prior covariances  (log-precision)
M.T    = Y;                    % data structure

U      = [Y.U];                % outputs to model
A      = [Y.age];              % age bands

% initialisation
%--------------------------------------------------------------------------
if true
    load DCM_UK
    M.P   = pE;
    field = fieldnames(DCM.Ep);
    for i = 1:numel(field)
        if all(size(pE.(field{i})) == size(DCM.Ep.(field{i})))
            M.P.(field{i}) = DCM.Ep.(field{i});
        end
    end
    clear DCM
end

% model inversion with Variational Laplace (Gauss Newton)
%==========================================================================
[Ep,Cp,Eh,F] = spm_nlsi_GN(M,U,xY);

% save in DCM structure
%--------------------------------------------------------------------------
DCM.M  = M;
DCM.Ep = Ep;
DCM.Eh = Eh;
DCM.Cp = Cp;
DCM.F  = F;
DCM.Y  = S;
DCM.U  = U;
DCM.A  = A;

% return if just DCM is required
%--------------------------------------------------------------------------
if nargout, return, end

% posterior predictions
%==========================================================================
spm_figure('GetWin','United Kingdom'); clf;
%--------------------------------------------------------------------------
M.T       = 64 + datenum(date) - datenum(M.date,'dd-mm-yyyy');
u         = [find(U == 1,1) find(U == 2,1) find(U == 3,1)];
[H,X,~,R] = spm_SARS_gen(Ep,M,[1 2 3]);
spm_SARS_plot(H,X,S(:,u),[1 2 3])

spm_figure('GetWin','outcomes (1)');
%--------------------------------------------------------------------------
j     = 0;
k     = 0;
for i = 1:numel(Y)
    
    j = j + 1;
    subplot(4,2,j)
    spm_SARS_ci(Ep,Cp,S(:,i),U(i),M,[],A(i));
    title(Y(i).type,'FontSize',14), ylabel(Y(i).unit)
    
    % add R = 1 and current date
    %----------------------------------------------------------------------
    if Y(i).U == 4
        plot(get(gca,'XLim'),[1,1],'-.r')
        plot(datenum(date)*[1,1],get(gca,'YLim'),'-.b')
        set(gca,'YLim',[0 5]), ylabel('ratio')
    end
    
    % hold plot
    %----------------------------------------------------------------------
    if numel(Y) > 8
        if Y(i).hold
            j = j - 1; hold on
        end
    end
    
    % new figure
    %----------------------------------------------------------------------
    if j == 8
        if k > 0
            spm_figure('GetWin','outcomes (3)');
        else
            spm_figure('GetWin','outcomes (2)');
            k = k + 1;
        end
        j = 0;
    end
    
end

% time varying parameters
%==========================================================================

% infection fatality ratios (%)
%--------------------------------------------------------------------------
j     = j + 1;
subplot(4,2,j)
for i = 1:numel(N)
    spm_SARS_ci(Ep,Cp,[],21,M,[],i); hold on
end
ylabel('percent'), title('Infection fatality ratio','FontSize',14)

% transmission risk
%--------------------------------------------------------------------------
j    = j + 1;
subplot(4,2,j), hold on
plot([R{1}.Ptrn]), spm_axis tight
title('Transmission risk','FontSize',14)
xlabel('days'),ylabel('probability')
hold on, plot([1,1]*size(DCM.Y,1),[0,1/2],':'), box off

% contact rate
%--------------------------------------------------------------------------
j    = j + 1;
subplot(4,2,j), hold on
for i = 1:numel(R)
    plot([R{i}.Pout])
end
spm_axis tight
title('Contact rate','FontSize',14)
xlabel('days'),ylabel('probability')
hold on, plot([1,1]*size(DCM.Y,1),[0,1/2],':'), box off

% case fatality ratio
%--------------------------------------------------------------------------
j    = j + 1;
subplot(4,2,j), hold on
for i = 1:numel(R)
    plot(100 * [R{i}.Pfat])
end
spm_axis tight
title('Fatality risk | ARDS','FontSize',14)
xlabel('days'),ylabel('percent')
hold on, plot([1,1]*size(DCM.Y,1),[0,1/2],':'), box off
legend({'<15yrs','15-35yrs','35-70yrs','>70yrs'})


%% long-term forecasts Newton(six months from the current data)
%==========================================================================
spm_figure('GetWin','outcomes (4)'); clf

Ep  = DCM.Ep;
Cp  = DCM.Cp;
M   = DCM.M;
M.T = 30*6 + datenum(date) - datenum(M.date,'dd-mm-yyyy');
t   = (1:M.T) + datenum(M.date,'dd-mm-yyyy');

% infection fatality ratios (%)
%--------------------------------------------------------------------------
subplot(3,1,1)
spm_SARS_ci(Ep,Cp,[],19,M); hold on
spm_SARS_ci(Ep,Cp,[],20,M); hold on
ylabel('cases per 100,000'), title('Incidence per 100,000','FontSize',14)
plot(datenum(date)*[1,1],get(gca,'YLim'),':')
legend({'CI per day','actual cases per day','CI per week','confirmed cases per week'})

subplot(3,1,2)
spm_SARS_ci(Ep,Cp,[],2,M); hold on
plot(datenum(date)*[1,1],get(gca,'YLim'),':')
legend({'CI per day','people testing positive'})

subplot(3,1,3)
spm_SARS_ci(Ep,Cp,[],28,M); hold on
plot(datenum(date)*[1,1],get(gca,'YLim'),':')
legend({'CI per day','Incidence'})


%% switch windows
%--------------------------------------------------------------------------
spm_figure('GetWin','long-term (1)'); clf

% fatalities
%--------------------------------------------------------------------------
subplot(2,1,1)

i   = find(DCM.U == 1,1);  D = DCM.Y(:,i); spm_SARS_ci(Ep,Cp,D,1,M);  hold on
i   = find(DCM.U == 15,1); D = DCM.Y(:,i); spm_SARS_ci(Ep,Cp,D,15,M); hold on

plot(datenum(date,'dd-mm-yyyy')*[1,1],get(gca,'YLim'),':k')
ylabel('number per day'), title('Daily deaths','FontSize',14)
legend({'CI 28-day','PCR test within 28 days','ONS','CI certified','certified deaths'})
legend boxoff
drawnow

% lockdown and mobility
%--------------------------------------------------------------------------
subplot(2,1,2)
i       = find(DCM.U == 14,1); D = DCM.Y(:,i);
[~,~,q] = spm_SARS_ci(Ep,Cp,D,14,M); hold on


% thresholds
%--------------------------------------------------------------------------
% q  = spm_SARS_gen(Ep,M,14); plot(t,q); hold on
%--------------------------------------------------------------------------
u1   = datenum('10-May-2020','dd-mmm-yyyy') - t(1) + 1;
u2   = datenum('10-Aug-2020','dd-mmm-yyyy') - t(1) + 1;
u3   = datenum('10-Sep-2020','dd-mmm-yyyy') - t(1) + 1;
U    = sort([0 q(u1) q(u2) q(u3)]); U(end) = 95;
dstr = datestr(t,'dd-mmm');

% loop over levels
%==========================================================================
for i = 1:numel(U)
    
    % intervals for this level
    %----------------------------------------------------------------------
    if i == 1
        j  = find(q <= U(i + 1));
    elseif i == numel(U)
        j  = find(q >= U(i));
    else
        j  = find(q >= U(i) & q <= U(i + 1));
    end
    
    % Timeline
    %----------------------------------------------------------------------
    for k = 1:numel(j)
        try
            fill(t(j(k) + [0 1 1 0]),[0 0 1 1]*32,'r', ...
                'FaceAlpha',(numel(U) - i)/16,'Edgecolor','none')
        end
    end
    
    % label level crossings
    %----------------------------------------------------------------------
    if i <numel(U)
        j = find((q(1:end - 1) <= U(i + 1)) & (q(2:end) > U(i + 1)));
    else
        j = [];
    end
    for k = 1:numel(j)
        text(t(j(k)),i*8,dstr(j(k),:),'Color','k','FontSize',10)
    end
    
    % plot levels
    %----------------------------------------------------------------------
    plot([t(1),t(end)],U(i)*[1,1],':r')
    
end

% UEFA EURO 2020/Dates
%--------------------------------------------------------------------------
d1 = datenum('11-Jun-2021','dd-mmm-yyyy');
d2 = datenum('11-Jul-2021','dd-mmm-yyyy');
plot([d1,d2],[120,120],'k','Linewidth',8)
text(d1 - 84,120,'EURO 2020','FontSize',10)


ylabel('percent'),  title('Mobility and lockdown','FontSize',14)
legend({'credible interval','mobility (%)','Google workplace'}), legend boxoff
drawnow


%% prevalence and reproduction ratio
%--------------------------------------------------------------------------
spm_figure('GetWin','long-term (2)'); clf

subplot(2,1,1)
i   = find(DCM.U == 4,1);
Rt  = DCM.Y(:,i);
spm_SARS_ci(Ep,Cp,[],11,M); hold on
[~,~,q,c] = spm_SARS_ci(Ep,Cp,Rt,4 ,M); hold on

j   = find(t == datenum(date));
q   = q(j);
d   = sqrt(c{1}(j,j))*1.64;
str = sprintf('Prevalence and reproduction ratio (%s): R = %.2f (CI %.2f to %.2f)',datestr(date,'dd-mmm-yy'),q,q - d,q + d);

% attack rate, herd immunity and herd immunity threshold
%--------------------------------------------------------------------------
E         = 1 - mean(exp(Ep.ves));
[H,~,~,R] = spm_SARS_gen(Ep,M,[4 29 26]);
i         = 8:32;                           % pre-pandemic period
TRN       = [R{1}.Ptrn];                    % transmission risk
R0        = mean(H(i,1));                   % basic reproduction ratio
RT        = R0*TRN(:)/mean(TRN(i));         % effective reproduction ratio
HIT       = 100 * (1 - 1./RT)/E;            % herd immunity threshold
VAC       = H(:,2);                         % percent of people vaccinated

% Add R0
%--------------------------------------------------------------------------
alpha = datenum('20-Sep-2020','dd-mmm-yyyy');
delta = datenum('20-Mar-2021','dd-mmm-yyyy');
plot(t,RT)
text(alpha,4,'alpha','FontSize',10)
text(delta,4,'delta','FontSize',10)

% add R = 1 and current dateline
%--------------------------------------------------------------------------
plot(get(gca,'XLim'),[1,1],':k')
plot(datenum(date,'dd-mm-yyyy')*[1,1],get(gca,'YLim'),':k')
set(gca,'YLim',[0 8]), ylabel('ratio or percent')
title(str,'FontSize',14)

legend({'CI prevalence','Prevalence (%)','CI R-number','R DCM','R SPI-M','R0'})
legend boxoff
drawnow

% attack rate, herd immunity and herd immunity threshold
%--------------------------------------------------------------------------
subplot(2,1,2)
spm_SARS_ci(Ep,Cp,[],25,M); hold on
spm_SARS_ci(Ep,Cp,[],26,M); hold on



% effective immunity threshold at 80% contact rates
%--------------------------------------------------------------------------
plot(t,HIT,'r',t,VAC), hold on
hit  = 100 * (1 - 1./(RT * .8))/E;            
plot(t,hit,'r-.',get(gca,'XLim'),[100 100],':k'), hold on
plot(datenum(date,'dd-mm-yyyy')*[1,1],[100 100],':k')
ylabel('percent'),  title('Attack rate and immunity','FontSize',14)
legend({'CI','Attack rate','CI','Population immunity',...
       'Effective immunity threshold',...
       'Vaccine antibodies',...
       'EIT at 80% contact rate'},'location','west')
legend boxoff


%% report vaccine efficiency
%--------------------------------------------------------------------------
q   = Ep.vef(end);
d   = spm_unvec(diag(Cp),Ep);
d   = sqrt(d.vef(end))*1.64;
qE  = 100*(1 - exp(q));
qL  = 100*(1 - exp(q + d));
qU  = 100*(1 - exp(q - d));
disp(sprintf('preventing exposure to infection: %.1f%s (CI %.1f to %.1f)',qE,'%',qL,qU))
q   = Ep.ves(end);
d   = spm_unvec(diag(Cp),Ep);
d   = sqrt(d.ves(end))*1.64;
qE  = 100*(1 - exp(q));
qL  = 100*(1 - exp(q + d));
qU  = 100*(1 - exp(q - d));
disp(sprintf('preventing transmission following infection %.1f%s (CI %.1f to %.1f)',qE,'%',qL,qU))
q   = Ep.lnk(2);
d   = spm_unvec(diag(Cp),Ep);
d   = sqrt(d.lnk(2))*1.64;
qE  = 100*(1 - exp(q));
qL  = 100*(1 - exp(q + d));
qU  = 100*(1 - exp(q - d));
disp(sprintf('preventing serious illness when symptomatic (age 15-34) %.1f%s (CI %.1f to %.1f)',qE,'%',qL,qU))
q   = Ep.lnk(3);
d   = spm_unvec(diag(Cp),Ep);
d   = sqrt(d.lnk(3))*1.64;
qE  = 100*(1 - exp(q));
qL  = 100*(1 - exp(q + d));
qU  = 100*(1 - exp(q - d));
disp(sprintf('preventing serious illness when symptomatic (age 35-70) %.1f%s (CI %.1f to %.1f)',qE,'%',qL,qU))
q   = Ep.lnf(end);
d   = spm_unvec(diag(Cp),Ep);
d   = sqrt(d.lnf(end))*1.64;
qE  = 100*(1 - exp(q));
qL  = 100*(1 - exp(q + d));
qU  = 100*(1 - exp(q - d));
disp(sprintf('preventing fatality when seriously ill %.1f%s (CI %.1f to %.1f)',qE,'%',qL,qU))
disp(' ')

q      = (mean(exp(Ep.Tin)) + mean(exp(Ep.Tcn))*mean(exp(Ep.ves))) /...
         (mean(exp(Ep.Tin)) + mean(exp(Ep.Tcn)));

infect = mean(exp(Ep.vef));
mild   = q*infect;
severe = mean(exp(Ep.lnk))*mild;
death  = mean(exp(Ep.lnf))*severe;
disp(sprintf('relative risk of infection %.1f%s',     infect*100,'%'))
disp(sprintf('relative risk of mild illness %.1f%s',  mild*100,'%'))
disp(sprintf('relative risk of severe illness %.1f%s',severe*100,'%'))
disp(sprintf('relative risk of fatality %.1f%s',      death*100,'%'))

%% report transmissibility and basic reproduction number
%--------------------------------------------------------------------------
disp('relative transmissibility');
disp(100*TRN(j)/mean(TRN(1:j)))
disp('basic reproduction number');
disp(RT(j))


%% save figures
%--------------------------------------------------------------------------
spm_figure('GetWin','outcomes (1)');
savefig(gcf,'Fig1')

spm_figure('GetWin','outcomes (2)');
savefig(gcf,'Fig2')

spm_figure('GetWin','outcomes (3)');
savefig(gcf,'Fig3')

spm_figure('GetWin','outcomes (4)');
savefig(gcf,'Fig4')

spm_figure('GetWin','United Kingdom');
savefig(gcf,'Fig5')

spm_figure('GetWin','long-term (2)');
savefig(gcf,'Fig6')

spm_figure('GetWin','long-term (1)');
savefig(gcf,'Fig7')

% Table
%--------------------------------------------------------------------------
Tab = spm_COVID_table(Ep,Cp,M)

save('DCM_UK.mat','DCM')
cd('C:\Users\karl\Dropbox\Coronavirus')
save('DCM_UK.mat','DCM')

return



%% NOTES
% postdoc fitting of age cohort-specific parameters
%==========================================================================
clear
DCM = load('DCM_UK.mat','DCM');
DCM = DCM.DCM;

% unpack model and posterior expectations
%--------------------------------------------------------------------------
M   = DCM.M;                                 % model (priors)
Ep  = DCM.Ep;                                % posterior expectation
Cp  = DCM.Cp;                                % posterior covariances
S   = DCM.Y;                                 % smooth timeseries
U   = DCM.U;                                 % indices of outputs
Y   = DCM.M.T; 

xY.y  = spm_vec(Y.Y);
xY.Q  = spm_Ce([Y.n]);

% empirical priors
%--------------------------------------------------------------------------
pE    = Ep;
pC    = spm_zeros(DCM.M.pC);

% augment priors
%--------------------------------------------------------------------------
nN      = numel(Ep.N);
k       = numel(Ep.tra)*2;
pE.mob  = zeros(nN,k);                       % fluctuations in mobility
pC.mob  = ones(nN,k)/8;                      % prior variance

% augment posteriors
%----------------------------------------------------------------------
M.pE      = pE;                    % empirical prior expectation
M.pC      = pC;                    % fix expectations
[Ep,Cp]   = spm_nlsi_GN(M,U,xY);   % new posterior expectation

return

% Notes for precision – increasing precision of recent (64 day) data
%==========================================================================
nY    = numel(Y);
Q     = [];
rdate = datenum(date) - 64;
for i = 1:numel(Y)
    j      = Y(i).date > rdate;
    q      = zeros(Y(i).n,nY);
    q(:,i) = 1;
    q(j,i) = 16;
    Q      = [Q; q];
end
nQ    = size(Q,1);
for i = 1:numel(Y)
    xY.Q{i} = sparse(1:nQ,1:nQ,Q(:,i));
end

% fluctuations (adiabatic mean field approximation)
%==========================================================================
for f = 1:numel(fluct)
    
    % augment priors
    %----------------------------------------------------------------------
    pE.(fluct{f})   = zeros(1,16);           % add new prior expectation
    pC.(fluct{f})   =  ones(1,16);           % add new prior covariance
    
    % augment posteriors
    %----------------------------------------------------------------------
    i               = 1:size(Cp,1);          % number of parameters
    C               = Cp;                    % empirical prior covariance
    M.pE            = Ep;                    % empirical prior expectation
    M.pC            = spm_zeros(M.pC);       % fix expectations
    M.pE.(fluct{f}) = zeros(1,16);           % add new prior expectation
    M.pC.(fluct{f}) =  ones(1,16);           % add new prior covariance
    
    [Ep,Cp,Eh,Ff]   = spm_nlsi_GN(M,U,xY);   % new posterior expectation
    Cp(i,i)         = C;                     % new posterior covariance
    F               = F + Ff;                % free energy
    
    % save priors
    %----------------------------------------------------------------------
    M.pE   = pE;
    M.pC   = pC;
    
end

return

%% age-group specific inversion
%--------------------------------------------------------------------------
a = 2;
N = N(a);
i = [Y.age] == a;
Y = Y(i);
S = S(:,i);
for i = 1:numel(Y)
    Y(i).age = 0;
end

% retrieve age-specific priors
%--------------------------------------------------------------------------
pE.Nin = pE.Nin(a,a);
pE.Nou = pE.Nou(a,a);
pC.Nin = pC.Nin(a,a);
pC.Nou = pC.Nou(a,a);
field = fieldnames(pE);
for i = 1:numel(field)
    if size(pE.(field{i}),1) > 1
        pE.(field{i}) = pE.(field{i})(a,:);
        pC.(field{i}) = pC.(field{i})(a,:);
    end
end



%% Interventions
%==========================================================================
clear
DCM = load('DCM_UK.mat','DCM');
DCM = DCM.DCM;

% unpack model and posterior expectations
%--------------------------------------------------------------------------
M   = DCM.M;                                 % model (priors)
Ep  = DCM.Ep;                                % posterior expectation
Cp  = DCM.Cp;                                % posterior covariances
S   = DCM.Y;                                 % smooth timeseries
U   = DCM.U;                                 % indices of outputs

% plot epidemiological trajectories and hold plots
%==========================================================================
spm_figure('GetWin','states'); clf;
%--------------------------------------------------------------------------
M.T    = datenum(date) - datenum(DCM.M.date,'dd-mm-yyyy');
M.T    = M.T + 180;

u      = 30;
a      = 0;
Ep.Trd = DCM.Ep.Trd + 0;

[Z,X]  = spm_SARS_gen(Ep,M,u,[],a);
j      = find(U == u(1));
try
spm_SARS_plot(Z,X,S(:,j(1)),u)
catch
    spm_SARS_plot(Z,X,[],u)
end
subplot(3,2,1), hold on

