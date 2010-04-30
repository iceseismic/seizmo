function [data,x,t]=convolve_source_timefunction(data,varargin)
%CONVOLVE_SOURCE_TIMEFUNCTION   Convolve source function on SEIZMO records
%
%    Usage:    data=convolve_source_timefunction(data,hwidth)
%              data=convolve_source_timefunction(data,hwidth,type)
%              [data,x,t]=convolve_source_timefunction(...)
%
%    Description: DATA=CONVOLVE_SOURCE_TIMEFUNCTION(DATA,HWIDTH) convolves
%     a gaussian source function onto records in SEIZMO struct DATA.
%     HWIDTH defines the half width of the source function and must be a
%     scalar or an array of size equal to the number of records in DATA.
%     Note that the gaussian is centered on each point, so the convolution
%     is an acausal operation.  The gaussian has unit area so that the
%     energy is preserved (see the last Usage format to get the actual
%     source function).  The returned records include extra points before
%     and after the time limits of the original records.  These points
%     are included because energy has been given to those points through
%     the convolution operation.
%
%     DATA=CONVOLVE_SOURCE_TIMEFUNCTION(DATA,HWIDTH,TYPE) specifies the
%     type of source function to be used in the convolution.  See function
%     MAKE_SOURCE_TIMEFUNCTION for valid values.  TYPE should be a string
%     like 'gaussian' or 'triangle' or a cellstr array with one string per
%     record in DATA.
%
%     [DATA,X,T]=CONVOLVE_SOURCE_TIMEFUNCTION(...) also exports the source
%     time functions in cell arrays X and T.  See MAKE_SOURCE_TIMEFUNCTION
%     for more info.
%
%    Notes:
%     - gaussian-type functions extend from about -1.5*HWIDTH to 1.5*HWIDTH
%     - triangle-type functions extend from about -HWIDTH to HWIDTH
%
%    Header changes: DEPMIN, DEPMEN, DEPMAX, NPTS, B, E
%
%    Examples:
%     Convolve a 10 second triangle source function onto some synthetic
%     data read into a SEIZMO dataset:
%      data=convolve_source_timefunction(data,10,'triangle');
%
%    See also: CONVOLVE, DECONVOLVE_SOURCE_TIMEFUNCTION, DECONVOLVE,
%              MAKE_SOURCE_TIMEFUNCTION, TRIANGLETF, GAUSSIANTF

%     Version History:
%        Oct. 18, 2009 - initial version
%        Oct. 19, 2009 - export source function too
%        Oct. 22, 2009 - fixed time adjust (only adjust b & e)
%        Oct. 28, 2009 - works with new convolve
%        Jan. 30, 2010 - fix checking state functions, better messages
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 30, 2010 at 20:15 GMT

% todo:

% check nargin
msg=nargchk(2,3,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data,'dep');
if(~isempty(msg)); error(msg.identifier,msg.message); end

% turn off struct checking
oldseizmocheckstate=seizmocheck_state(false);

% attempt header check
try
    % check header
    data=checkheader(data);
    
    % turn off header checking
    oldcheckheaderstate=checkheader_state(false);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

% attempt convolution
try
    % verbosity
    verbose=seizmoverbose;
    
    % number of records
    nrecs=numel(data);
    
    % get header info
    [b,e,delta]=getheader(data,'b','e','delta');
    leven=getlgc(data,'leven');
    iftype=getenumid(data,'iftype');
    
    % cannot do spectral/xyz records
    if(any(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy')))
        error('seizmo:convolve_source_timefunction:badIFTYPE',...
            ['Record(s):\n' sprintf('%d ',...
            find(~strcmpi(iftype,'itime') & ~strcmpi(iftype,'ixy'))) ...
            '\nDatatype of record(s) in DATA must be Timeseries or XY!']);
    end
    
    % cannot do unevenly sampled records
    if(any(strcmpi(leven,'false')))
        error('seizmo:convolve_source_timefunction:badLEVEN',...
            ['Record(s):\n' sprintf('%d ',find(strcmpi(leven,'false'))) ...
            '\nInvalid operation on unevenly sampled record(s)!']);
    end
    
    % pass to make_source_timefunction
    [x,t]=make_source_timefunction(delta,varargin{:});
    
    % get delay (in samples!)
    delay=nan(nrecs,1);
    for i=1:nrecs; delay(i)=t{i}(1); end
    delay=round(delay./delta);
    
    % convolve with records
    [data,zf]=convolve(data,x,delay);
    
    % attach final conditions
    if(verbose)
        disp('Attaching Convolution Final Conditions onto Record(s)');
    end
    data=attach(attach(data,'ending',zf(:,1)),'beginning',zf(:,2));
    
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    checkheader_state(oldcheckheaderstate);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    checkheader_state(oldcheckheaderstate);
    
    % rethrow error
    error(lasterror)
end

end