## Startup functions and global constants
## 
## Author: Matthew D. Furia <matt.furia@sagebase.org>
###############################################################################

kCertBundle <- "certificateBundle/cacert.pem"
kSynapseRAnnotationTypeMap <- list(
  stringAnnotations = "character",
  longAnnotations = "integer",
  doubleAnnotations = "numeric",
  dateAnnotations = "POSIXt"
)
kSupportedDataLocationTypes <- c("external", "awss3")


.onLoad <-
  function(libname, pkgname)
{
  tou <- "\nTERMS OF USE NOTICE:
When using Synapse, remember that the terms and conditions of use require that you:
  1) Attribute data contributors when discussing this data or results from this data.
  2) Not discriminate, identify, or recontact individuals or groups represented by the data.
  3) Use and contribute only data de-identified to HIPPA standards.
  4) Redistribute data only under these same terms of use.\n"
  
  
  ##set the R_OBJECT cache directory. check for a funcitonal zip first
  packageStartupMessage("Verifying zip installation")
  ff <- tempfile()
  file.create(ff)
  zipfile <- tempfile()
  suppressWarnings(
    ans <- utils::zip(zipfile, ff)
  )
  unlink(ff)
  unlink(zipfile, recursive = TRUE)
  if(ans != 0){
    packageStartupMessage("zip was not found on your system and so the Synapse funcionality related to file and object storage will be limited. To fix this, make sure that 'zip' is executable from your system's command interpreter.")
    .setCache("rObjCacheDir", .Platform$file.sep)
    .setCache("hasZip", FALSE)
  }else{
    packageStartupMessage("OK")
    .setCache("rObjCacheDir", ".R_OBJECTS")
    .setCache("hasZip", TRUE)
  }
  packageStartupMessage(tou)
  
  .setCache("curlOpts", list(low.speed.time=60, low.speed.limit=1, connecttimeout=300, followlocation=TRUE, ssl.verifypeer=TRUE, verbose = FALSE, cainfo=file.path(libname, pkgname, kCertBundle)))
  .setCache("curlHeader", c('Content-Type'="application/json", Accept = "application/json", "Accept-Charset"="utf-8"))
  .setCache("sessionRefreshDurationMin", 1440)
  .setCache("curlWriter", getNativeSymbolInfo("_writer_write", PACKAGE="synapseClient")$address)
  .setCache("curlReader", getNativeSymbolInfo("_reader_read", PACKAGE="synapseClient")$address)
  .setCache("synapseBannerPath", file.path(libname, pkgname, "images", "synapse_banner.gif"))
  .setCache("annotationTypeMap", kSynapseRAnnotationTypeMap)
  .setCache("anonymous", FALSE)
  .setCache("downloadSuffix", "unpacked")
  .setCache("debug", FALSE)
  
  synapseResetEndpoints()
  
  # used in entityToFileCache.R
  .setCache("ENTITY_FILE_NAME", "entity.json")
  .setCache("ANNOTATIONS_FILE_NAME", "annotations.json")
  
  synapseDataLocationPreferences(kSupportedDataLocationTypes)
  synapseCacheDir(gsub("[\\/]+", "/", path.expand("~/.synapseCache")))
  
  ## install cleanup hooks upon shutdown
  reg.finalizer(topenv(parent.frame()),
    function(...) .Last.lib(),
    onexit=TRUE)
  reg.finalizer(getNamespace("synapseClient"),
    function(...) .Last.lib(),
    onexit=TRUE)
}

.onUnload <- function(libpath) .Last.lib()

.Last.lib <- function(...) {
  if(!is.null(step <- synapseClient::getStep()))
    try(stoppedStep <- synapseClient::stopStep(step), silent=TRUE)
}

