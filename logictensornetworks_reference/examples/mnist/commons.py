from collections import defaultdict

def train(
        epochs,
        metrics_dict, 
        ds_train, 
        ds_test, 
        train_step, 
        test_step,
        csv_path=None,
        scheduled_parameters=defaultdict(lambda : {})
    ):
    """
    Args:
        epochs: int, number of training epochs.
        metrics_dict: dict, {"metrics_label": tf.keras.metrics instance}.
        ds_train: iterable dataset, e.g. using tf.data.Dataset.
        ds_test: iterable dataset, e.g. using tf.data.Dataset.
        train_step: callable function. the arguments passed to the function
            are the itered elements of ds_train.
        test_step: callable function. the arguments passed to the function
            are the itered elements of ds_test.
        csv_path: (optional) path to create a csv file, to save the metrics.
        scheduled_parameters: (optional) a dictionary that returns kwargs for
            the train_step and test_step functions, for each epoch.
            Call using scheduled_parameters[epoch].
    """
    template = "Epoch {}"
    for metrics_label in metrics_dict.keys():
        template += ", %s: {:.4f}" % metrics_label
    if csv_path is not None:
        csv_file = open(csv_path,"w+")
        headers = ",".join(["Epoch"]+list(metrics_dict.keys()))
        csv_template = ",".join(["{}" for _ in range(len(metrics_dict)+1)])
        csv_file.write(headers+"\n")
    
    for epoch in range(epochs):
        for metrics in metrics_dict.values():
            metrics.reset_state()

        import time
        import numpy as np
        
        n_batches = 0
        batch_times = []
        for batch_elements in ds_train:
            t0 = time.time()
            train_step(*batch_elements,**scheduled_parameters[epoch])
            t1 = time.time()
            batch_times.append((t1 - t0) * 1000)
            n_batches += 1
            
        for batch_elements in ds_test:
            test_step(*batch_elements,**scheduled_parameters[epoch])
            
        # Drop the first batch to ignore the massive TensorFlow JIT compilation overhead spike
        valid_times = batch_times[1:] if len(batch_times) > 1 else batch_times
        train_ms_batch = np.mean(valid_times) if len(valid_times) > 0 else 0
        train_std_batch = np.std(valid_times) if len(valid_times) > 0 else 0
        print(f"Epoch {epoch} Train: {train_ms_batch:.2f} +- {train_std_batch:.2f} ms/batch")

        metrics_results = [metrics.result() for metrics in metrics_dict.values()]
        print(template.format(epoch,*metrics_results))
        if csv_path is not None:
            csv_file.write(csv_template.format(epoch,*metrics_results)+"\n")
            csv_file.flush()
    if csv_path is not None:
        csv_file.close()