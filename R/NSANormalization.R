###########################################################################/**
# @RdocClass NSANormalization
#
# @title "The NSANormalization class"
#
# \description{
#  @classhierarchy
#
#  This class represents the NSA normalization method [1], which 
#  looks for normal regions within the tumoral samples.
# }
#                                                                                                                                                          
# @synopsis 
#
# \arguments{
#   \item{data}{A named @list with data set named \code{"total"} and
#     \code{"fracB"} where the former should be of class
#     @see "aroma.core::AromaUnitTotalCnBinarySet" and the latter of
#     class @see "aroma.core::AromaUnitFracBCnBinarySet".  The
#     two data sets must be for the same chip type, have the same
#     number of samples and the same sample names.}
#   \item{tags}{Tags added to the output data sets.}
#   \item{...}{Not used.}
# }
#
# \section{Fields and Methods}{
#  @allmethods "public"  
# }
# 
# \examples{\dontrun{
#   @include "../incl/NSANormalization.Rex"
# }}
#
# \references{
#   [1] ...
# }
#
# \seealso{
#   Low-level versions of the NSA normalization method is available
#   via the @see "NSAByTotalAndFracB.matrix" methods.
# }
#
#*/###########################################################################
setConstructorS3("NSANormalization", function(data=NULL, tags="*", ...) {
  # Validate arguments
  if (!is.null(data)) {
    if (!is.list(data)) {
      throw("Argument 'data' is not a list: ", class(data)[1]);
    }
    reqNames <- c("total", "fracB");
    ok <- is.element(reqNames, names(data));
    if (!all(ok)) {
      throw(sprintf("Argument 'data' does not have all required elements (%s): %s", paste(reqNames, collapse=", "), paste(reqNames[!ok], collapse=", ")));
    }
    data <- data[reqNames];

    # Assert correct classes
    className <- "AromaUnitTotalCnBinarySet";
    ds <- data$total;
    if (!inherits(ds, className)) {
      throw(sprintf("The 'total' data set is not of class %s: %s", className, class(ds)[1]));
    }

    className <- "AromaUnitFracBCnBinarySet";
    ds <- data$fracB;
    if (!inherits(ds, className)) {
      throw(sprintf("The 'total' data set is not of class %s: %s", className, class(ds)[1]));
    }

    # Assert that the chip types are compatile
    if (getChipType(data$total) != getChipType(data$fracB)) {
      throw("The 'total' and 'fracB' data sets have different chip types: ", 
            getChipType(data$total), " != ", getChipType(data$fracB));
    }

    # Assert that the data sets have the same number data files
    if (nbrOfFiles(data$total) != nbrOfFiles(data$fracB)) {
      throw("The number of samples in 'total' and 'fracB' differ: ", 
            nbrOfFiles(data$total), " != ", nbrOfFiles(data$fracB));
    }

    # Assert that the data sets have the same samples
    if (!identical(getNames(data$total), getNames(data$fracB))) {
      throw("The samples in 'total' and 'fracB' have different names.");
    }
  }

  # Arguments '...':
  args <- list(...);
  if (length(args) > 0) {
    argsStr <- paste(names(args), collapse=", ");
    throw("Unknown arguments: ", argsStr);
  }

  this <- extend(Object(...), "NSANormalization",
    .data = data
  );

  setTags(this, tags);

  this; 
})


setMethodS3("as.character", "NSANormalization", function(x, ...) {
  # To please R CMD check
  this <- x;

  s <- sprintf("%s:", class(this)[1]);

  dsList <- getDataSets(this);
  s <- c(s, sprintf("Data sets (%d):", length(dsList)));
  for (kk in seq(along=dsList)) {
    ds <- dsList[[kk]];
    s <- c(s, sprintf("<%s>:", capitalize(names(dsList)[kk])));
    s <- c(s, as.character(ds));
  } 
 
  class(s) <- "GenericSummary";
  s;
}, private=TRUE)



setMethodS3("getAsteriskTags", "NSANormalization", function(this, collapse=NULL, ...) {
  tags <- "NSAN";

  if (!is.null(collapse)) {
    tags <- paste(tags, collapse=collapse);
  }
  
  tags;
}, private=TRUE) 


setMethodS3("getName", "NSANormalization", function(this, ...) {
  dsList <- getDataSets(this);
  ds <- dsList$total;
  getName(ds);
}) 



setMethodS3("getTags", "NSANormalization", function(this, collapse=NULL, ...) {
  # "Pass down" tags from input data set
  dsList <- getDataSets(this);
  ds <- dsList$total;
  tags <- getTags(ds, collapse=collapse);

  # Get class-specific tags
  tags <- c(tags, this$.tags);

  # Update default tags
  tags[tags == "*"] <- getAsteriskTags(this, collapse=",");

  # Collapsed or split?
  if (!is.null(collapse)) {
    tags <- paste(tags, collapse=collapse);
  } else {
    tags <- unlist(strsplit(tags, split=","));
  }

  if (length(tags) == 0)
    tags <- NULL;

  tags;
})


setMethodS3("setTags", "NSANormalization", function(this, tags="*", ...) {
  # Argument 'tags':
  if (!is.null(tags)) {
    tags <- Arguments$getCharacters(tags);
    tags <- trim(unlist(strsplit(tags, split=",")));
    tags <- tags[nchar(tags) > 0];
  }
  
  this$.tags <- tags;
})


setMethodS3("getFullName", "NSANormalization", function(this, ...) {
  name <- getName(this);
  tags <- getTags(this);
  fullname <- paste(c(name, tags), collapse=",");
  fullname <- gsub("[,]$", "", fullname);
  fullname;
})


setMethodS3("getDataSets", "NSANormalization", function(this, ...) {
  this$.data;
})
 

setMethodS3("getRootPath", "NSANormalization", function(this, ...) {
  "totalAndFracBData";
})


setMethodS3("getPath", "NSANormalization", function(this, create=TRUE, ...) {
  # Create the (sub-)directory tree for the data set

  # Root path
  rootPath <- getRootPath(this);

  # Full name
  fullname <- getFullName(this);

  # Chip type    
  dsList <- getDataSets(this);
  ds <- dsList$total;
  chipType <- getChipType(ds, fullname=FALSE);

  # The full path
  path <- filePath(rootPath, fullname, chipType, expandLinks="any");

  # Verify that it is not the same as the input path
  inPath <- getPath(ds);
  if (getAbsolutePath(path) == getAbsolutePath(inPath)) {
    throw("The generated output data path equals the input data path: ", path, " == ", inPath);
  }

  # Create path?
  if (create) {
    if (!isDirectory(path)) {
      mkdirs(path);
      if (!isDirectory(path))
        throw("Failed to create output directory: ", path);
    }
  }

  path;
})


setMethodS3("nbrOfFiles", "NSANormalization", function(this, ...) {
  dsList <- getDataSets(this);
  ds <- dsList$total;
  nbrOfFiles(ds);
})


setMethodS3("getOutputDataSets", "NSANormalization", function(this, ..., verbose=FALSE) {
  # Argument 'verbose':
  verbose <- Arguments$getVerbose(verbose);
  if (verbose) {
    pushState(verbose);
    on.exit(popState(verbose));
  } 
                                   
  res <- allocateOutputDataSets(this, ..., verbose=less(verbose, 10));
  this$.outputDataSets <- res;
  res;
}) 


setMethodS3("allocateOutputDataSets", "NSANormalization", function(this, arrays=NULL, ..., verbose=FALSE) {
  # Argument 'verbose':
  verbose <- Arguments$getVerbose(verbose);
  if (verbose) {
    pushState(verbose);
    on.exit(popState(verbose));
  } 
  verbose && enter(verbose, "Retrieve/allocation output data sets");
  dsList <- getDataSets(this);
  path <- getPath(this);
  
  res <- list();
  ds <- dsList[[2]];
  verbose && enter(verbose, sprintf("NormalRegions ('%s')", getName(ds)));

  for (ii in arrays) {    
    df <- getFile(ds, ii);
    verbose && enter(verbose, sprintf("Data file #%d ('%s') of %d",
                                      ii, getName(df), length(arrays)));

    filename <- getFilename(df);
    filename <- paste(unlist(strsplit(filename, split=","))[1], ",normalReg.asb",sep="")
    
    pathname <- Arguments$getWritablePathname(filename, path=path, 
                                                     mustNotExist=FALSE);
    # Skip?
    if (isFile(pathname)) {
      verbose && cat(verbose, "Already exists. Skipping.");
      verbose && exit(verbose);
      next;
    }
    # Create temporary file
    pathnameT <- sprintf("%s.tmp", pathname);
    pathnameT <- Arguments$getWritablePathname(pathnameT, mustNotExist=TRUE);

    # Copy source file
    copyFile(getPathname(df), pathnameT);

    # Make it empty by filling it will missing values
    # AD HOC: We should really allocate from scratch here. /HB 2010-06-21
    dfT <- newInstance(df, pathnameT);
    dfT[,1] <- NA;

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Renaming temporary file
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    verbose && enter(verbose, "Renaming temporary output file");
    file.rename(pathnameT, pathname);
    if (!isFile(pathname)) {
      throw("Failed to rename temporary file ('", pathnameT, "') to final file ('", pathname, "')");
    }
    verbose && exit(verbose);

    verbose && cat(verbose, "Copied: ", pathname);
    verbose && exit(verbose);
  } # for (ii ...)
  verbose && exit(verbose);
  
  dsOut <- byPath(ds, path=path, ...);
  # AD HOC: The above byPath() grabs all *.asb files. /HB 2010-06-20

  res[[1]] <- dsOut;
  rm(ds, dsOut);
  names(res) <- "normalReg"
  this$.outputDataSets <- res;

  verbose && exit(verbose);
  res;
}, protected=TRUE)

setMethodS3("findArraysTodo", "NSANormalization", function(this, arrays, ..., verbose=FALSE) {
  # Argument 'verbose':
  verbose <- Arguments$getVerbose(verbose);
  if (verbose) {
    pushState(verbose);
    on.exit(popState(verbose));
  } 

  verbose && enter(verbose, "Finding arrays to do");

  # List of the input samples
  dsList <- getDataSets(this);
  ds <- dsList[[length(dsList)]];
  verbose && print(verbose, ds);

  # List of the output samples
  dsListOut <- this$.outputDataSets;
  dsOut <- dsListOut[[length(dsListOut)]];
  outputSamples <- getNames(dsOut);
  verbose && print(verbose, dsOut);  

  # checking if the last chromosome has been done, this means
  # the array has been already done
  chipType <- getChipType(ds, fullname=TRUE);
  cdf <- AffymetrixCdfFile$byChipType(chipType);
  gi <- getGenomeInformation(cdf);
  units <- getUnitsOnChromosome(gi, 22);    

  sampleDone <- NULL;
  arraysTodo <- NULL;
  # checking only the first chromosome of the each array

  for (ii in arrays) {    
    df <- getFile(ds, ii);
    verbose && enter(verbose, sprintf("Data file #%d ('%s') of %d",
                                      ii, getName(df), length(arrays)));
    filename <- getFilename(df);
    filename <- unlist(strsplit(filename, split=","))[1]

    verbose && print(verbose, df);

    sampleDone <- match(filename, outputSamples);

    df <- getFile(dsOut, sampleDone);
  
    # Read one unit of chromosome 1
    values <- df[units[1:10],1,drop=TRUE];    
    
    # Identify all missing values
    if(sum(is.na(values))>5)
      arraysTodo <- c(arraysTodo, ii);
    
    verbose && exit(verbose);      
  }
  verbose && printf(verbose, "Samples to do: %d\n", 
                         length(arraysTodo));
  verbose && str(verbose, arraysTodo);
  verbose && exit(verbose);
  arraysTodo;
})
###########################################################################/**
# @RdocMethod process
#
# @title "Finds normal regions within tumoral samples"
#
# \description{
#  @get "title".
# }
#
# @synopsis
#
# \arguments{
#   \item{...}{Additional arguments passed to 
#     @see "aroma.light::normalizeFragmentLength" (only for advanced users).}
#   \item{arrays}{Index vector indicating which samples to process.}
#   \item{force}{If @TRUE, data already normalized is re-normalized, 
#       otherwise not.}
#   \item{verbose}{See @see "R.utils::Verbose".}
# }
#
# \value{
#  Returns a @double @vector.
# }
#
# \seealso{
#   @seeclass
# }
#*/###########################################################################

setMethodS3("process", "NSANormalization", function(this, arrays=NULL, ..., force=FALSE, ram=NULL, verbose=FALSE) {
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Validate arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  dsList <- getDataSets(this);
  dsTCN <- dsList$total;
  dsBAF <- dsList$fracB;
  
  chipType <- getChipType(dsTCN, fullname=TRUE);
  cdf <- AffymetrixCdfFile$byChipType(chipType);
  gi <- getGenomeInformation(cdf);
  
  verbose && cat(verbose, "Genome Information File: ", gi);  
  
  # Argument "arrays"
  if(is.null(arrays)){
    arrays <- seq(1:nbrOfFiles(this));
  }
  
  if (!is.null(arrays) && (max(arrays) > nbrOfFiles(this) || min(arrays)<1)){
    throw(sprintf("Wrong samples' indexes."));
  }
  
  # Argument 'ram':
  ram <- getRam(aromaSettings, ram);

  # Argument 'verbose':
  verbose <- Arguments$getVerbose(verbose);
  if (verbose) {
    pushState(verbose);
    on.exit(popState(verbose));
  }

  verbose && enter(verbose, "NSA normalization of ASCNs");
  nbrOfFiles <- length(arrays);
  verbose && cat(verbose, "Number of arrays: ", nbrOfFiles);

  chipType <- getChipType(dsTCN, fullname=FALSE);
  verbose && cat(verbose, "Chip type: ", chipType);
  rm(dsList);

  sampleNames <- getNames(dsTCN);
  dimnames <- list(NULL, sampleNames, c("total", "fracB"));

  outPath <- getPath(this);


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Allocate output data sets
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  res <- getOutputDataSets(this, arrays = arrays, ..., verbose=less(verbose, 5));
  ds <- res[[1]];
  outputSamples <- getNames(ds);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Find arrays to do
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if (!force)
    arrays <- findArraysTodo(this, arrays, verbose=less(verbose, 5));
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Find chromosomes to do
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  chromosomes <- c(1:22);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Process by array
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  count <- 1;
  for(kk in arrays){

    dfTotal <- getFile(dsTCN, kk);
    dfFracB <- getFile(dsBAF, kk);

    verbose && enter(verbose, sprintf("Data file #%d ('%s') of %d", 
                                       count, getName(dfTotal), length(arrays)));
    filename <- getFilename(dfTotal);
    filename <- unlist(strsplit(filename, split=","))[1]
    verbose && print(verbose, dfTotal);
    sampleDone <- match(filename, outputSamples);

    dfout <- getFile(ds, sampleDone);

    
    for(chr in chromosomes){

      verbose && enter(verbose, sprintf("Chromosome %s", chr));
      units <- getUnitsOnChromosome(gi, chr);
      pos <- getPositions(gi, units = units);
      units <- units[order(pos)];

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Reading (total,fracB) data
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      verbose && enter(verbose, "Reading (total,fracB) data");
      total <- dfTotal[units,drop=TRUE];
      verbose && str(verbose, total);

      fracB <- dfFracB[units,drop=TRUE];
      verbose && str(verbose, fracB);
      verbose && exit(verbose);
    
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Combining the data
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      verbose && enter(verbose, "Combining into an (total,fracB) array");
      data <- c(total, fracB);
      data <- array(data, dim=c(length(total),2));
      dimnames(data)[[2]]<-c("total","fracB");
      rm(total, fracB);
      verbose && str(verbose, data);
      verbose && exit(verbose);

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Finding Normal Regions
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
      verbose && enter(verbose, "Finding normal regions:");
      dataN <- NSAByTotalAndFracB(data, chromosome=chr, ..., verbose=less(verbose,5));
      fit <- attr(dataN, "modelFit");
      verbose && str(verbose, fit);
      verbose && str(verbose, dataN);
      verbose && exit(verbose);
  
      rm(data);  # Not needed anymore
      gc <- gc();
      verbose && print(verbose, gc);

      signals <- dataN[,1];
      verbose && cat(verbose, "Signals:");
      verbose && str(verbose, signals);

      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Storing normalized data
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      verbose && enter(verbose, "Storing normalized data");
      dfout[units,1] <- signals;
      rm(signals);
      verbose && exit(verbose);

      verbose && exit(verbose);

   } #for chromosomes

  verbose && exit(verbose);
  count <- count+1;
} #for arrays
  verbose && exit(verbose);
  invisible(res);
})

############################################################################
# HISTORY:
# 2010-06-24
# o Created from CalMaTeNormalization.R.
############################################################################
