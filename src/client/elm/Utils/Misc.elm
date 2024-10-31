module Utils.Misc exposing (sleep)

import Process
import Task
import Time


sleep : m -> Time.Time -> Cmd m
sleep msg timeout =
    Process.sleep (timeout)
        |> Task.perform (\_ -> msg)
