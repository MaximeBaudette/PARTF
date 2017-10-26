%function s_simuToFile (filename,time,freq,rocof,bus_v,ilf,ilt,PMULocations,line)
%% Create CSV file
app_sel=2;
app={'LSE' 'GMV'}; app=app{app_sel};

nbus=sum(bus_v(:,1)~=0);
NoiseVariance=0;
PMULocations=[1];  PMULocations=sort(PMULocations);
num_pmu=length(PMULocations);
setPosSeq=0;
user_dir = winqueryreg('HKEY_CURRENT_USER','SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders','Personal');
switch app
    case 'LSE'
        csv_path=[user_dir '\PARTF\Tests\LSE\Inputdata\DynamicEvent_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv'];
    case 'GMV'
        csv_path=[user_dir '\PARTF\Tests\GMV\Inputdata\DynamicEvent_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv'];
end

time=t;
bus_vol = (abs(bus_v)+sqrt(NoiseVariance)*randn(size(bus_v))).*...
    exp(1i*(angle(bus_v)+sqrt(NoiseVariance)*randn(size(bus_v))));
freq=diff(phase(bus_v(PMULocations,:)),1,2)/(t(2)-t(1))/(2*pi)+ str2double(basdat{2});
freq=[freq freq(:,end)];
rocof=diff(freq,1,2)/(t(2)-t(1));
rocof=[rocof rocof(:,end)];

fid=fopen(csv_path, 'wt');
FromBus=line(:,1);
ToBus=line(:,2);


voltages=[];
for i=1:num_pmu
    for j=1:length(time)
        [real_v, imag_v, posSeq]=conv3phase2(bus_vol(PMULocations(i),j),setPosSeq);
        voltages{i}(j,:) = [reshape([real_v; imag_v],1,[]) posSeq];
    end
end

currents=[];
for i=1:num_pmu
    ToBusBranch=find(ToBus==bus(PMULocations(i),1));
    FromBusBranch=find(FromBus==bus(PMULocations(i),1));
    for j=1:length(time)
        [real_it, imag_it, posSeq_t]=conv3phase2(ilt(ToBusBranch,j),setPosSeq);
        [real_if, imag_if, posSeq_f]=conv3phase2(ilf(FromBusBranch,j),setPosSeq);
        currents{i}(j,:)= [reshape([real_it; imag_it],1,[]) posSeq_t reshape([real_if; imag_if],1,[]) posSeq_f];
    end
end

if(setPosSeq)
    fprintf(fid,['PMU_ID, Time, Freq, ROCOF,' ...
    'VA_Real, VA_Imag, VB_Real, VB_Imag, VC_Real, VC_Imag, V+_Real, V+_Imag,'...
    'IA_Real, IA_Imag, IB_Real, IB_Imag, IC_Real, IC_Imag, I+_Real, I+_Imag,'...
    '\n']);
else
     fprintf(fid,['PMU_ID, Time, Freq, ROCOF,' ...
    'VA_Real, VA_Imag, VB_Real, VB_Imag, VC_Real, VC_Imag,'...
    'IA_Real, IA_Imag, IB_Real, IB_Imag, IC_Real, IC_Imag,'...
    '\n']);
end


row=1;
for i=1:length(time)
    for j=1:num_pmu
        M=[j time(i) freq(j,i) rocof(j,i) voltages{j}(i,:) currents{j}(i,:)];
        for h=1:length(M)
            fprintf(fid,'%.15f',M(h));
            if(h<length(M))
                fprintf(fid,', ');
            end
        end
        fprintf(fid,'\n');
        row=row+1;
    end
end

fclose(fid);
%csvwrite(filename,M);

%end

%% Create CSV file

switch app
    case 'LSE'
        reference_path=[user_dir '\PARTF\Tests\LSE\Inputdata\VoltageReferences_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv'];
    case 'GMV'
        reference_path=[user_dir '\PARTF\Tests\GMV\Inputdata\VoltageReferences_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv'];
end

fid = fopen(reference_path, 'wt' );

data_ref=bus_vol(1:nbus,:).';
for i=1:size(data_ref,1) 
    for j=1:size(data_ref,2)
        fprintf(fid,'%+.15f%+.15fi',real(data_ref(i,j)),imag(data_ref(i,j)));
        if(j<size(data_ref,2))
            fprintf(fid,',');
        end
    end
    fprintf(fid,'\n');
end

fclose(fid);
%csvwrite(reference_path,bus_vol(1:nbus,:).');



%% Create TST file

% Event
Start_Time=num2str(t(1));
End_Time=num2str(t(end));
if(~setPosSeq)
    bPosSeq='FALSE';
else
    bPosSeq='TRUE';
end
Nominal_Frequency='60';
if(strcmp(Nominal_Frequency,'60'))
    Reporting_Rate='60';
    Fsamp='960';
else
    Reporting_Rate='50';
    Fsamp='1000';
end
% PMU Impairment
PmuImpairPluginINIFilePath='C37BehaviourPlugin/C37BehaviourPlugin.ini';
FilterType='Blackman';
PmuImpairParams1='8.19';
PmuImpairParams2='164';



% File creation;
switch app
    case 'LSE'
        file_path=[user_dir '\PARTF\Tests\LSE\DynamicSystem_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.tst'];
    case 'GMV'
        file_path=[user_dir '\PARTF\Tests\GMV\DynamicSystem_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.tst'];
end
fid = fopen(file_path, 'wt' );

if(fid==-1)
    usersChosenFolder = uigetdir();
    file_path=[usersChosenFolder '\DynamicSystem_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.tst'];
    fid = fopen(file_path, 'wt' );
end

app_string={'LSE' 'GMV'};
app_string=app_string{app_sel};

for i=1:num_pmu
fprintf(fid,['[Bus' num2str(i) ']\n']);
fprintf(fid,['BusNumber = "' num2str(i) '"\n']);
fprintf(fid,'EvtPluginINIFilePath = "EventFromCSVPlugin/EventFromCSVPlugin.ini"\n');
fprintf(fid,'EvtParams.<size(s)> = "%d %d"\n',1,1);
fprintf(fid,'EvtParams 0 = "%s"\n',[app_string '\Inputdata\DynamicEvent_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv']);
fprintf(fid,['EvtConfig.UTC Time 0 = "\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00"\n',...
'EvtConfig.Nominal Frequency = "', Nominal_Frequency,'"\n',...
'EvtConfig.Reporting Rate = "' Reporting_Rate,'"\n',...
'EvtConfig.Fsamp = "', Fsamp,'"\n',...
'EvtConfig.PosSeq = "', bPosSeq, '"\n',...
'Start Time = "', Start_Time, '"\n',...
'End Time = "', End_Time, '"\n',...
'PmuImpairPluginINIFilePath = "', PmuImpairPluginINIFilePath '"\n',...
'PmuImpairParams.<size(s)> = "','2 1','"\n',...
'PmuImpairParams 0 = "', PmuImpairParams1,'"\n',...
'PmuImpairParams 1 = "', PmuImpairParams2,'"\n',...
'PmuImpairConfig.FilterType = "', FilterType,'"\n',...
'PmuImpairConfig.bPosSeq = "', bPosSeq,'"\n',...
'NetImpPluginINIFilePath = "NetworkPluginNone/NetworkPluginNone.ini"\n',...
'NetImpParams.<size(s)> = "0 0"\n',...
'FlagImpPluginINIFilePath = "NoFlagImpairPlugin/NoFlagImpairPlugin.ini"\n',...
'FlagImpParams.<size(s)> = "0 0"\n']);
fprintf(fid,'\n');
end

%% AppConfig
switch(app)
    case 'LSE'
        fprintf(fid,'[AppData]\n');
        fprintf(fid,'AppData.AppPluginIniFilePath = "LSEPlugin/LSEPlugin.ini"\n');
        fprintf(fid,['AppData.Config = "<Cluster>\\0D\\0A<Name>LSEConfig</Name>\\0D\\0A<NumElts>6</NumElts>\\0D\\0A<DBL>\\0D\\0A<Name>NoiseVariance</Name>\\0D\\0A<Val>' num2str(NoiseVariance)]);
        fprintf(fid,['</Val>\\0D\\0A</DBL>\\0D\\0A<U32>\\0D\\0A<Name>IEEESystem</Name>\\0D\\0A<Val>' num2str(nbus)]);
        fprintf(fid,['</Val>\\0D\\0A</U32>\\0D\\0A<Array>\\0D\\0A<Name>PMULocations</Name>\\0D\\0A<Dimsize>' num2str(num_pmu) '</Dimsize>\\0D\\0A']);
        for i=1:num_pmu
            fprintf(fid,['<U32>\\0D\\0A<Name>Numeric</Name>\\0D\\0A<Val>' num2str(PMULocations(i)) '</Val>\\0D\\0A</U32>\\0D\\0A']);
        end
    fprintf(fid,'</Array>\\0D\\0A<I32>\\0D\\0A<Name>Vindex</Name>\\0D\\0A<Val>0</Val>\\0D\\0A</I32>\\0D\\0A<I32>\\0D\\0A<Name>Iindex</Name>\\0D\\0A<Val>3</Val>\\0D\\0A</I32>\\0D\\0A<String>\\0D\\0A<Name>DynamicRef</Name>\\0D\\0A<Val>%s</Val>\\0D\\0A</String>\\0D\\0A</Cluster>\\0D\\0A"',['LSE\Inputdata\VoltageReferences_case' num2str(nbus) '_' num2str(num_pmu) 'pmus.csv']);
    fprintf(fid,'\n\n');
    case 'GMV'
        fprintf(fid,'[AppData]\n');
        fprintf(fid,'AppData.AppPluginIniFilePath = "ModelValidationPlugin/ModelValidationPlugin.ini"\n');
        fprintf(fid,'AppData.Config = "<Cluster>\\0D\\0A<Name>ModelValidationConfig</Name>\\0D\\0A<NumElts>5</NumElts>\\0D\\0A<DBL>\\0D\\0A<Name>NoiseVariance</Name>\\0D\\0A<Val>1.00000000000000E-3</Val>\\0D\\0A</DBL>\\0D\\0A<I32>\\0D\\0A<Name>Iindex</Name>\\0D\\0A<Val>3</Val>\\0D\\0A</I32>\\0D\\0A<DBL>\\0D\\0A<Name>OffsetTime</Name>\\0D\\0A<Val>2.00000000000000</Val>\\0D\\0A</DBL>\\0D\\0A<I32>\\0D\\0A<Name>InterpolationFactor</Name>\\0D\\0A<Val>5</Val>\\0D\\0A</I32>\\0D\\0A<Cluster>\\0D\\0A<Name>Initial condition</Name>\\0D\\0A<NumElts>3</NumElts>\\0D\\0A<DBL>\\0D\\0A<Name>H0</Name>\\0D\\0A<Val>4.55000000000000</Val>\\0D\\0A</DBL>\\0D\\0A<DBL>\\0D\\0A<Name>xd0</Name>\\0D\\0A<Val>0.27500000000000</Val>\\0D\\0A</DBL>\\0D\\0A<DBL>\\0D\\0A<Name>D0</Name>\\0D\\0A<Val>4.20000000000000</Val>\\0D\\0A</DBL>\\0D\\0A</Cluster>\\0D\\0A</Cluster>\\0D\\0A"');
        fprintf(fid,'\n\n');
    otherwise
        error('Select a valid app')
end
       

%% OutToFileConfig

fprintf(fid,'[OutToFileConfig]\n');
fprintf(fid,'OutToFileConfig.OutputToFilePluginINIFilePath = "OutputToFileBasePlugin/OutputToFileBasePlugin.ini"\n');
fprintf(fid,'OutToFileConfig.Output File Path = "Output"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.TIME_BASE = "\\00\\00\\00\\00\\00\\0FB@"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.STN = "Bus_1"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.IDCODE = "0"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.rdoPolRect = "Rectangular"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.rdoFloatInt = "Float"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.PHUNIT = "\\00\\00\\00\\00\\00\\0FB@"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.rdoFreqDfreq = "Float"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM.<size(s)> = "8"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 0 = "VA"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 1 = "VB"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 2 = "VC"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 3 = "V+"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 4 = "IA"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 5 = "IB"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 6 = "IC"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.CHNAM 7 = "I+"\n');
fprintf(fid,'OutToFileConfig.clConfigOptions.chkCfg2Prefix = "TRUE"\n');

fclose(fid);


