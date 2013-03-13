#' USGS data availability
#'
#' Imports a table of available parameters, period of record, and count.
#'
#' @param siteNumber string USGS site number.  This is usually an 8 digit number
#' @param interactive logical Option for interactive mode.  If true, there is user interaction for error handling and data checks.
#' @param longNames logical
#' @keywords data import USGS web service
#' @return retval dataframe with all information found in the expanded site file
#' @export
#' @examples
#' # These examples require an internet connection to run
#' siteINFO <- getSiteFileData('05114000',interactive=FALSE)
getSiteFileData <- function(siteNumber="",interactive=TRUE){
  
  # Checking for 8 digit site ID:
  siteNumber <- formatCheckSiteNumber(siteNumber, longNames = FALSE,interactive=interactive)
  
  urlSitefile <- paste("http://waterservices.usgs.gov/nwis/site?format=rdb&siteOutput=Expanded&sites=",siteNumber,sep = "")
  
  SiteFile <- read.delim(  
    urlSitefile, 
    header = TRUE, 
    quote="\"", 
    dec=".", 
    sep='\t',
    colClasses=c('character'),
    fill = TRUE, 
    comment.char="#")
  
  SiteFile <- SiteFile[-1,]
  
  SiteFile <- with(SiteFile, data.frame(parameter_cd=parm_cd, statCd=stat_cd, startDate=begin_date,endDate=end_date, count=count_nu,service=data_type_cd,stringsAsFactors = FALSE))
  
  SiteFile <- SiteFile[!is.na(SiteFile$parameter_cd),]
  SiteFile <- SiteFile["" != SiteFile$parameter_cd,]
  SiteFile$startDate <- as.Date(SiteFile$startDate)
  SiteFile$endDate <- as.Date(SiteFile$endDate)
  SiteFile$count <- as.numeric(SiteFile$count)
  
  if(longNames){
    pCodes <- unique(SiteFile$pCode)
    numObs <- length(pCodes)
    printUpdate <- floor(seq(1,numObs,numObs/100))
    for (i in 1:numObs){
      if (1 == i) {
        pcodeINFO <- getParameterInfo(pCodes[i])
      } else {
        pcodeINFO <- rbind(pcodeINFO, getParameterInfo(pCodes[i]))
      }
      if(interactive) {
        cat("Percent complete: \n")
        if(i %in% printUpdate) cat(floor(i*100/numObs),"\t")
      }
    }
    SiteFile <- merge(SiteFile,pcodeINFO,by="parameter_cd")
  }
  
  return(SiteFile)
}