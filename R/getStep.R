## Interact with provenance steps
## 
## Author: Nicole Deflaux <nicole.deflaux@sagebase.org>
###############################################################################

setGeneric(
  name = "getStep",
  def = function(step){
    standardGeneric("getStep")
  }
)

setMethod(
  f = "getStep",
  signature = "SynapseEntity",
  definition = function(step){
    getStep(propertyValue(step, "id"))
  }
)

setMethod(
  f = "getStep",
  signature = "numeric",
  definition = function(step) {
    getStep(as.character(step))
  }
)

setMethod(
  f = "getStep",
  signature = "missing",
  definition = function() {
    getStep(NA_character_)
  }
)

setMethod(
  f = "getStep",
  signature = "character",
  definition = function(step) {
    ## If we were not passed a step, get the current step
    if(missing(step) || is.na(step)) {
      step <-	.getCache("currentStep")
    }
    
    if(!is.null(step))
      step <- getEntity(step)
    step
  }
)

