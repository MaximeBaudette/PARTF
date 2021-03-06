function [EvtTimestamp,...
          EvtSynx,...
          EvtFreq,...
          EvtROCOF] = UserEvtRptWrapper(EvtType,...
                                       Time,...
                                       EvtParams,...
                                       T0,...
                                       F0)
% To add a user event plugin, add a case with the appropriate
% event type, then call your user-defined Mathscript function
% within the case.
switch EvtType
    case '60255Harm'
         [EvtTimestamp,EvtSynx,EvtFreq,EvtROCOF] = Harm60255Rpt(...
                                                   T0,...
                                                   F0,...
                                                   Time,...
                                                   EvtParams);
    case 'User1'
        [EvtTimestamp,EvtSynx,EvtFreq,EvtROCOF] = userfunc1(...
                                                   T0,...
                                                   F0,...
                                                   Time,...
                                                   EvtParams);
    case 'User2'
        [EvtTimestamp,EvtSynx,EvtFreq,EvtROCOF] = userfunc2(...
                                                   T0,...
                                                   F0,...
                                                   Time,...
                                                   EvtParams);
    otherwise
        msgStr = sprintf('EventType %s not found in UserEvtRptWrapper.m',EvtType);
        error(msgStr);
  
end
