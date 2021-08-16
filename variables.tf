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

###########
# Environment
###########
variable "env_stage" {
  description = "Service environment stage name"
  type        = string
  default     = "Dev"
}

variable "service_name" {
  description = "Service name"
  type        = string
  default     = ""
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = ""
}
