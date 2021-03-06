## Download a file from Synapse
## 
## Author: Matthew D. Furia <matt.furia@sagebase.org>
###############################################################################

legalFilePath<-function(filePath) {
	gsub("[()`'<>\"|?*]", "_", filePath)
}

synapseDownloadToLegalFile<- function(url, destfile, opts = opts, curlHandle = curlHandle) {
	legalDestFile <- legalFilePath(destfile)

	## download to temp file first so that the existing local file (if there is one) is left in place
	## if the download fails
	tmpFile <- tempfile()
	tryCatch(
			.curlWriterDownload(url=url, destfile=tmpFile, opts = opts, curlHandle = curlHandle),
			error = function(ex){
				file.remove(tmpFile)
				stop(ex)
			}
	)
	
	## copy then delete. this avoids a cross-device error encountered
	## on systems with multiple hard drives when using file.rename
	if(!file.copy(tmpFile, legalDestFile, overwrite = TRUE)){
		file.remove(tmpFile)
		stop("COULD NOT COPY: ", tmpFile, " TO: ", legalDestFile)
	}
	file.remove(tmpFile)

	legalDestFile
}

synapseDownloadFile  <- 
  function (url, checksum, curlHandle = getCurlHandle(), cacheDir = synapseCacheDir(), opts = .getCache("curlOpts"))
{
	if (is.null(cacheDir)) stop(paste("cacheDir is required. synapseCacheDir() returns ", synapseCacheDir()))
	
  ## Download the file to the cache
  parsedUrl <- .ParsedUrl(url)
  destfile <- file.path(cacheDir, gsub("^/", "", parsedUrl@path))
  destfile <- path.expand(destfile)
  
  ## temporary hack for github url that does not contain file extension
  if( parsedUrl@host=="github.com" ){
    splits <- strsplit(parsedUrl@pathPrefix, "/")
    if( splits[[1]][length(splits[[1]])] == "zipball" )
      destfile <- paste(destfile, ".zip", sep="")
    if( splits[[1]][length(splits[[1]])] == "tarball" )
      destfile <- paste(destfile, ".tar", sep="")
  }
  
  synapseDownloadFileToDestination(url=url, checksum=checksum, destfile=destfile, opts=opts)
}

synapseDownloadFileToDestination  <- 
  function (url, destfile, checksum, curlHandle = getCurlHandle(), opts = .getCache("curlOpts"))
{
  ## Download the file to a user-specified location
  ## if checksum is missing, don't check local file before 
  ## download
  if(file.exists(destfile) & !missing(checksum)) {
    localFileChecksum <- as.character(tools::md5sum(destfile))
    if(checksum == localFileChecksum) {
      # No need to download
      return(destfile)
    }
  }
  
  splits <- strsplit(destfile, .Platform$file.sep)
  downloadDir <- path.expand(paste(splits[[1]][-length(splits[[1]])], collapse=.Platform$file.sep))
  downloadFileName <- splits[[1]][length(splits[[1]])]
  if(!file.exists(downloadDir)){
    dir.create(downloadDir, recursive=TRUE)
  }
  
  ## download to temp file first so that the existing local file (if there is one) is left in place
  ## if the download fails
  tmpFile <- tempfile()
  tryCatch(
    .curlWriterDownload(url=url, destfile=tmpFile, opts = opts, curlHandle = curlHandle),
    error = function(ex){
      file.remove(tmpFile)
      stop(ex)
    }
  )
  
  ## check the md5sum of the tmpFile to see if it matches the one passed to the function
  if (file.exists(tmpFile) & !missing(checksum)){
    if (as.character(tools::md5sum(tmpFile)) != as.character(checksum)){
      stop(paste("The md5 ", as.character(tools::md5sum(tmpFile)), " of ", downloadFileName, " does not match the md5 ", as.character(checksum), " recorded in Synapse", sep=""))
    }
  }
  
  ## copy then delete. this avoids a cross-device error encountered
  ## on systems with multiple hard drives when using file.rename
  if(!file.copy(tmpFile, destfile, overwrite = TRUE)){
    file.remove(tmpFile)
    stop("COULD NOT COPY: ", tmpFile, " TO: ", destfile)
  }
  file.remove(tmpFile)
  return(destfile)
}
