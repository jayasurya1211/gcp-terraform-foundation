variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bucket_suffix" {
  type    = string
  default = "raw-tf"
}

variable "dataset_id" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}