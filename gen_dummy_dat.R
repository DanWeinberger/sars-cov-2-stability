

df <- cbind.data.frame('t'=c(0,0,0,1,1,1),
                      'replicate'=c(1,2,3,1,2,3),
                      'surface_material'= rep('textured_plastic',6),
                      'humidity_level' = c(50,50,50,50,50,50),
                      'temp' = c(20,20,20,20,20,20),
                      'pfu' =rep(NA,6),
                      'ct'=rep(NA,6)
)
