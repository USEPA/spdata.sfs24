#' Conductivity NLA Data
#'
#' @description Conductivity NLA Data
#'
#' @format An \code{sf} object with 162 rows and 5 columns:
#'
#' \itemize{
#'   \item COMID: text
#'   \item COND_RESULT: text
#'   \item AREA_HA: text
#'   \item year: text
#'   \item geometry: \code{POINT} geometry representing coordinates in a
#'   NAD83 projection (EPSG: 5070).
#' }
"cond_nla_data"

#' Conductivity Model Data
#'
#' @description Conductivity Model Data
#'
#' @format An \code{sf} object with 162 rows and 11 columns:
#'
#' \itemize{
#'   \item COMID: text
#'   \item COND_RESULT: text
#'   \item AREA_HA: text
#'   \item year: text
#'   \item TMEAN8110CAT: text
#'   \item PRECIP8110WS: text
#'   \item CAOWS: text
#'   \item SWS: text
#'   \item PCTCROPWS: text
#'   \item PCTURBWS: text
#'   \item geometry: \code{POINT} geometry representing coordinates in a
#'   NAD83 projection (EPSG: 5070).
#' }
"cond_model_data"

#' Argia Model Data
#'
#' @description Argia Model Data
#'
#' @format An \code{sf} object with 550 rows and 15 columns:
#'
#' \itemize{
#'   \item SampleID: text
#'   \item ProjectLabel: text
#'   \item CollectionDate: text
#'   \item presence: text
#'   \item year: text
#'   \item COMID: text
#'   \item WSAREASWKM: text
#'   \item ELEVWS: text
#'   \item WETINDEXWS: text
#'   \item BFIWS: text
#'   \item PRECIP8110WS: text
#'   \item PCTWETLANDXXXXWS: text
#'   \item PCTIMPXXXXWSRP100: text
#'   \item TMEANPRISMXXXXPT: text
#'   \item geometry: \code{POINT} geometry representing coordinates in a
#'   NAD83 projection (EPSG: 5070).
#' }
"argia_model_data"

#' Argia Prediction Data
#'
#' @description Argia Prediction Data
#'
#' @format An \code{sf} object with 12,101 rows and 10 columns:
#'
#' \itemize{
#'   \item COMID: text
#'   \item WSAREASWKM: text
#'   \item ELEVWS: text
#'   \item WETINDEXWS: text
#'   \item BFIWS: text
#'   \item PRECIP8110WS: text
#'   \item PCTWETLANDXXXXWS: text
#'   \item PCTIMPXXXXWSRP100: text
#'   \item TMEANPRISMXXXXPT: text
#'   \item geometry: \code{POINT} geometry representing coordinates in a
#'   NAD83 projection (EPSG: 5070).
#' }
"argia_pred_data"

#' Argia Prediction Data (Small)
#'
#' @description Argia Prediction Data (Small)
#'
#' @format An \code{sf} object with 100 rows and 10 columns:
#'
#' \itemize{
#'   \item COMID: text
#'   \item WSAREASWKM: text
#'   \item ELEVWS: text
#'   \item WETINDEXWS: text
#'   \item BFIWS: text
#'   \item PRECIP8110WS: text
#'   \item PCTWETLANDXXXXWS: text
#'   \item PCTIMPXXXXWSRP100: text
#'   \item TMEANPRISMXXXXPT: text
#'   \item geometry: \code{POINT} geometry representing coordinates in a
#'   NAD83 projection (EPSG: 5070).
#' }
"argia_pred_data_small"

#' Argia Sample Location COMIDs
#'
#' @description Argia Sample Location COMIDs
#'
#' @format A character vector of COMIDs for the sample locations in
#'   \code{argia_model_data}.
"comids"
