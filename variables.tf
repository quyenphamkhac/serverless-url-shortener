###########
# Function
###########

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "nodejs12.x"
}


variable "memory_size" {
  description = "Lambda function memory size"
  type        = number
  default     = 512
}
