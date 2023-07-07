package de.abstractolotl.aztube;

import org.jetbrains.annotations.NotNull;

import java.util.HashMap;

public abstract class GenericStageProgressUpdater<T extends Enum<T>> {

    protected HashMap<T, Double> stages;
    protected HashMap<T, Double> weights;

    public GenericStageProgressUpdater(Class<T> clazz) {
        stages = new HashMap<>();

        var constants = clazz.getEnumConstants();
        for (var value : constants) {
            stages.put(value, 0.0);
            weights.put(value, 1.0 / constants.length);
        }
    }

    public GenericStageProgressUpdater(HashMap<T, Double> weights) {
        if(weights.size() == 0) throw new RuntimeException("Cannot create " + getClass() + " from empty weights.");

        Class<T> clazz = (Class<T>) weights.keySet().iterator().next().getClass();
        if(weights.size() != clazz.getEnumConstants().length) throw new RuntimeException("Need a weight for every value");

        this.weights = weights;
        this.stages = new HashMap<>();
        for(var key : weights.keySet()) {
            stages.put(key, 0.0);
        }
    }

    protected double calculateWeightedProgress() {
        double progress = 0;
        for(var entry : stages.entrySet()) {
            progress += entry.getValue() * weights.get(entry.getKey());
        };
        return progress;
    }

    public void updateStage(@NotNull T stage, double progress) {
        stages.put(stage, progress);
        performUpdate();
    }

    protected abstract void performUpdate();

}
